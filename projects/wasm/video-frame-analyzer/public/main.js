// ========================================
// WASM Module & Memory
// ========================================
let wasm;
let memory;

// ========================================
// Video & Canvas Elements
// ========================================
let video;
let canvas;
let ctx;
let statusOverlay;

// ========================================
// State Variables
// ========================================
let isAnalyzing = false;
let stream = null;
let previousFramePtr = null;
let previousBrightness = 0;
let frameCount = 0;
let lastFrameTime = 0;
let currentFPS = 0;

// Target FPS for analysis
let targetFPS = 30;

// ========================================
// Initialize WASM
// ========================================
async function initWasm() {
    console.log("Loading WASM module...");

    // Add cache-busting parameter to ensure fresh load
    const response = await fetch(`video_frame_analyzer.wasm?v=${Date.now()}`);
    const bytes = await response.arrayBuffer();

    memory = new WebAssembly.Memory({
        initial: 256,
        maximum: 1024
    });

    const result = await WebAssembly.instantiate(bytes, {
        env: { memory },
    });

    wasm = result.instance.exports;

    console.log("✅ WASM Loaded. Exports:", Object.keys(wasm));
    console.log("✅ Total exports:", Object.keys(wasm).length);

    // Verify critical functions exist
    if (!wasm.alloc) {
        console.error("❌ ERROR: alloc function not found in exports!");
        console.error("Available exports:", Object.keys(wasm));
    }
}

// ========================================
// Initialize UI & Camera
// ========================================
window.onload = async () => {
    // Get DOM elements
    video = document.getElementById("videoPreview");
    canvas = document.getElementById("hiddenCanvas");
    ctx = canvas.getContext("2d", { willReadFrequently: true });
    statusOverlay = document.getElementById("statusOverlay");

    // Initialize WASM
    await initWasm();

    // Setup event listeners
    document.getElementById("startBtn").addEventListener("click", startAnalysis);
    document.getElementById("stopBtn").addEventListener("click", stopAnalysis);
    document.getElementById("screenshotBtn").addEventListener("click", takeScreenshot);
    document.getElementById("fpsSelect").addEventListener("change", (e) => {
        targetFPS = parseInt(e.target.value);
    });

    // Enumerate cameras
    await enumerateCameras();

    console.log("✅ Application ready");
};

// ========================================
// Enumerate Available Cameras
// ========================================
async function enumerateCameras() {
    try {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(device => device.kind === 'videoinput');

        const cameraSelect = document.getElementById("cameraSelect");
        cameraSelect.innerHTML = "";

        videoDevices.forEach((device, index) => {
            const option = document.createElement("option");
            option.value = device.deviceId;
            option.text = device.label || `Camera ${index + 1}`;
            cameraSelect.appendChild(option);
        });

        // Add change listener
        cameraSelect.addEventListener("change", async () => {
            if (isAnalyzing) {
                await stopAnalysis();
                await startAnalysis();
            }
        });

    } catch (error) {
        console.error("Error enumerating cameras:", error);
    }
}

// ========================================
// Start Video Stream & Analysis
// ========================================
async function startAnalysis() {
    try {
        const cameraSelect = document.getElementById("cameraSelect");
        const selectedCamera = cameraSelect.value;

        const constraints = {
            video: {
                deviceId: selectedCamera ? { exact: selectedCamera } : undefined,
                width: { ideal: 1280 },
                height: { ideal: 720 }
            }
        };

        stream = await navigator.mediaDevices.getUserMedia(constraints);
        video.srcObject = stream;

        // Wait for video to be ready
        await new Promise(resolve => {
            video.onloadedmetadata = () => {
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
                resolve();
            };
        });

        isAnalyzing = true;
        frameCount = 0;
        lastFrameTime = performance.now();

        // Update UI
        document.getElementById("startBtn").disabled = true;
        document.getElementById("stopBtn").disabled = false;
        document.getElementById("screenshotBtn").disabled = false;
        updateStatusBadge("Analyzing", "analyzing");

        // Clear alerts
        clearAlerts();

        // Start analysis loop
        requestAnimationFrame(analysisLoop);

        console.log("✅ Analysis started");

    } catch (error) {
        console.error("Error starting analysis:", error);
        alert("Failed to access camera: " + error.message);
    }
}

// ========================================
// Stop Analysis
// ========================================
async function stopAnalysis() {
    isAnalyzing = false;

    if (stream) {
        stream.getTracks().forEach(track => track.stop());
        stream = null;
    }

    video.srcObject = null;

    // Free previous frame memory
    if (previousFramePtr) {
        const len = canvas.width * canvas.height * 4;
        wasm.free(previousFramePtr, len);
        previousFramePtr = null;
    }

    // Update UI
    document.getElementById("startBtn").disabled = false;
    document.getElementById("stopBtn").disabled = true;
    document.getElementById("screenshotBtn").disabled = true;
    updateStatusBadge("Ready", "");

    console.log("⏹ Analysis stopped");
}

// ========================================
// Main Analysis Loop
// ========================================
function analysisLoop(timestamp) {
    if (!isAnalyzing) return;

    // Calculate FPS
    const elapsed = timestamp - lastFrameTime;
    const targetInterval = 1000 / targetFPS;

    // Only process at target FPS
    if (elapsed >= targetInterval) {
        lastFrameTime = timestamp;
        processFrame();
        frameCount++;

        // Update FPS display
        currentFPS = Math.round(1000 / elapsed);
        document.getElementById("fpsValue").textContent = currentFPS;
        document.getElementById("frameCountValue").textContent = frameCount;
    }

    requestAnimationFrame(analysisLoop);
}

// ========================================
// Process Single Frame
// ========================================
function processFrame() {
    const startTime = performance.now();

    // Draw current frame to canvas
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const len = imageData.data.length;

    // Allocate WASM memory for current frame
    const ptr = wasm.alloc(len);
    const wasmBytes = new Uint8Array(memory.buffer, ptr, len);
    wasmBytes.set(imageData.data);

    // Run analysis functions
    const brightness = wasm.analyzeBrightness(ptr, len);
    const blurScore = wasm.detectBlur(ptr, len, canvas.width, canvas.height);
    const faceScore = wasm.detectFacePresence(ptr, len, canvas.width, canvas.height);

    let motionScore = 0;
    let cheatingFlags = 0;

    if (previousFramePtr) {
        motionScore = wasm.calculateMotion(ptr, previousFramePtr, len);
        cheatingFlags = wasm.detectCheating(
            ptr,
            len,
            canvas.width,
            canvas.height,
            previousFramePtr,
            previousBrightness
        );

        // Free old previous frame
        wasm.free(previousFramePtr, len);
    }

    // Store current frame as previous for next iteration
    previousFramePtr = wasm.alloc(len);
    const prevWasmBytes = new Uint8Array(memory.buffer, previousFramePtr, len);
    prevWasmBytes.set(imageData.data);
    previousBrightness = brightness;

    // Free current frame
    wasm.free(ptr, len);

    // Update UI with metrics
    updateMetrics(brightness, blurScore, faceScore, motionScore);
    handleCheatingAlerts(cheatingFlags);

    // Update performance stats
    const processTime = (performance.now() - startTime).toFixed(2);
    document.getElementById("processTimeValue").textContent = `${processTime}ms`;
}

// ========================================
// Update Metrics Display
// ========================================
function updateMetrics(brightness, blurScore, faceScore, motionScore) {
    // Brightness (0-255)
    document.getElementById("brightnessValue").textContent = brightness;
    document.getElementById("brightnessBar").style.width = `${(brightness / 255) * 100}%`;

    // Blur Score (normalize to 0-100 for display)
    const blurPercent = Math.min(100, (blurScore / 100));
    document.getElementById("blurValue").textContent = blurScore;
    document.getElementById("blurBar").style.width = `${blurPercent}%`;

    // Face Presence (0-100)
    document.getElementById("faceValue").textContent = `${faceScore}%`;
    document.getElementById("faceBar").style.width = `${faceScore}%`;

    // Motion (normalize to 0-100)
    const motionPercent = Math.min(100, motionScore);
    document.getElementById("motionValue").textContent = motionScore;
    document.getElementById("motionBar").style.width = `${motionPercent}%`;
}

// ========================================
// Handle Cheating Detection Alerts
// ========================================
function handleCheatingAlerts(flags) {
    const alerts = [];

    // Bit 0: Multiple faces
    if (flags & (1 << 0)) {
        alerts.push({ type: "warning", message: "⚠️ Multiple faces detected" });
    }

    // Bit 1: Sudden brightness change
    if (flags & (1 << 1)) {
        alerts.push({ type: "warning", message: "💡 Sudden brightness change" });
    }

    // Bit 2: Excessive motion
    if (flags & (1 << 2)) {
        alerts.push({ type: "warning", message: "🏃 Excessive motion detected" });
    }

    // Bit 3: No face detected
    if (flags & (1 << 3)) {
        alerts.push({ type: "info", message: "👤 No face detected" });
    }

    // Bit 4: Looking away
    if (flags & (1 << 4)) {
        alerts.push({ type: "warning", message: "👀 Looking away from camera" });
    }

    // Update alerts display
    if (alerts.length > 0) {
        displayAlerts(alerts);
        updateStatusBadge("Alert", "alert");
    } else {
        updateStatusBadge("Analyzing", "analyzing");
    }
}

// ========================================
// Display Alerts
// ========================================
function displayAlerts(alerts) {
    const container = document.getElementById("alertsContainer");
    container.innerHTML = "";

    alerts.forEach(alert => {
        const alertDiv = document.createElement("div");
        alertDiv.className = `alert-item ${alert.type}`;
        alertDiv.textContent = alert.message;
        container.appendChild(alertDiv);
    });
}

// ========================================
// Clear Alerts
// ========================================
function clearAlerts() {
    const container = document.getElementById("alertsContainer");
    container.innerHTML = '<div class="alert-placeholder">No alerts</div>';
}

// ========================================
// Update Status Badge
// ========================================
function updateStatusBadge(text, className) {
    const badge = statusOverlay.querySelector(".status-badge");
    badge.textContent = text;
    badge.className = `status-badge ${className}`;
}

// ========================================
// Take Screenshot
// ========================================
function takeScreenshot() {
    if (!canvas) return;

    // Create a temporary canvas with metrics overlay
    const screenshotCanvas = document.createElement("canvas");
    screenshotCanvas.width = canvas.width;
    screenshotCanvas.height = canvas.height;
    const screenshotCtx = screenshotCanvas.getContext("2d");

    // Draw current frame
    screenshotCtx.drawImage(canvas, 0, 0);

    // Add timestamp overlay
    screenshotCtx.fillStyle = "rgba(0, 0, 0, 0.7)";
    screenshotCtx.fillRect(10, 10, 300, 40);
    screenshotCtx.fillStyle = "white";
    screenshotCtx.font = "16px monospace";
    screenshotCtx.fillText(`Frame: ${frameCount}`, 20, 30);
    screenshotCtx.fillText(new Date().toLocaleTimeString(), 20, 45);

    // Download
    screenshotCanvas.toBlob(blob => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `frame_${frameCount}_${Date.now()}.png`;
        a.click();
        URL.revokeObjectURL(url);
    });

    console.log("📸 Screenshot saved");
}
