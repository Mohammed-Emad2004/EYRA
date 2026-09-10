"""
Ultralytics YOLOv8 Ultra High-FPS Web Application (Flask + Ultra-Fast Client-side Canvas Rendering)
"""

import sys
import time
import base64
from pathlib import Path
import cv2
import numpy as np
import torch
from flask import Flask, render_template_string, request, jsonify

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: Ultralytics package is not installed.")
    sys.exit(1)

# PyTorch CPU Speed Optimizations
torch.set_num_threads(max(1, torch.get_num_threads()))
torch.set_grad_enabled(False)

app = Flask(__name__)

# Global model state
CURRENT_MODEL_NAME = "yolov8s.pt"
model = YOLO(CURRENT_MODEL_NAME)
CONF_THRESHOLD = 0.35
IOU_THRESHOLD = 0.45
INFERENCE_IMGSZ = 640  # Upgraded from 320 for accuracy

SNAPSHOT_DIR = Path("snapshots")
SNAPSHOT_DIR.mkdir(exist_ok=True)

# HTML Template with Ultra-Fast Client-Side Bounding Box Canvas Rendering
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YOLOv8 Ultra High-FPS AI Vision</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0a0c10;
            --bg-card: rgba(18, 22, 33, 0.8);
            --border-color: rgba(0, 240, 255, 0.2);
            --accent-cyan: #00f0ff;
            --accent-green: #00ff88;
            --accent-purple: #9d4edd;
            --text-primary: #f0f4f8;
            --text-muted: #8a99ad;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Outfit', sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            overflow-x: hidden;
            background-image: 
                radial-gradient(circle at 10% 20%, rgba(0, 240, 255, 0.06) 0%, transparent 40%),
                radial-gradient(circle at 90% 80%, rgba(157, 78, 221, 0.06) 0%, transparent 40%);
        }

        header {
            padding: 1.2rem 2rem;
            background: rgba(10, 12, 16, 0.85);
            backdrop-filter: blur(16px);
            border-bottom: 1px solid var(--border-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .brand-logo {
            width: 38px;
            height: 38px;
            background: linear-gradient(135deg, var(--accent-cyan), var(--accent-purple));
            border-radius: 10px;
            display: grid;
            place-items: center;
            font-weight: 700;
            color: #000;
            box-shadow: 0 0 15px rgba(0, 240, 255, 0.4);
        }

        .brand-title {
            font-size: 1.4rem;
            font-weight: 700;
            letter-spacing: -0.5px;
            background: linear-gradient(90deg, #fff, var(--accent-cyan));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .badge-fps {
            background: rgba(0, 240, 255, 0.15);
            border: 1px solid var(--accent-cyan);
            color: var(--accent-cyan);
            padding: 4px 14px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            font-family: 'JetBrains Mono', monospace;
        }

        .main-container {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 24px;
            padding: 2rem;
            max-width: 1600px;
            margin: 0 auto;
            width: 100%;
            flex: 1;
        }

        @media (max-width: 1024px) {
            .main-container {
                grid-template-columns: 1fr;
            }
        }

        .viewport-card {
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 1rem;
            backdrop-filter: blur(12px);
            display: flex;
            flex-direction: column;
            position: relative;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
        }

        .viewport-wrapper {
            position: relative;
            width: 100%;
            aspect-ratio: 16 / 9;
            background: #000;
            border-radius: 12px;
            overflow: hidden;
        }

        #webcamVideo {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }

        #outputCanvas {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
        }

        .viewport-overlay {
            position: absolute;
            top: 16px;
            left: 16px;
            display: flex;
            gap: 12px;
        }

        .stat-badge {
            background: rgba(10, 12, 16, 0.8);
            backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.15);
            padding: 6px 14px;
            border-radius: 8px;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.85rem;
            color: var(--accent-cyan);
        }

        .controls-panel {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        .panel-card {
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 1.5rem;
            backdrop-filter: blur(12px);
        }

        .panel-title {
            font-size: 1.1rem;
            font-weight: 600;
            margin-bottom: 1rem;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .control-group {
            margin-bottom: 1.2rem;
        }

        .control-group label {
            display: block;
            font-size: 0.85rem;
            color: var(--text-muted);
            margin-bottom: 6px;
        }

        select, input[type="range"] {
            width: 100%;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: var(--text-primary);
            padding: 10px;
            border-radius: 8px;
            font-family: inherit;
            outline: none;
        }

        select:focus {
            border-color: var(--accent-cyan);
        }

        .range-value {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.85rem;
            color: var(--accent-cyan);
            float: right;
        }

        .btn {
            width: 100%;
            padding: 12px;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            font-size: 0.95rem;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--accent-cyan), #00a8ff);
            color: #000;
            box-shadow: 0 4px 15px rgba(0, 240, 255, 0.3);
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 240, 255, 0.4);
        }

        .btn-secondary {
            background: rgba(255, 255, 255, 0.08);
            color: var(--text-primary);
            border: 1px solid rgba(255, 255, 255, 0.15);
            margin-top: 8px;
        }

        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.15);
        }

        .objects-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
            max-height: 250px;
            overflow-y: auto;
        }

        .object-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 12px;
            background: rgba(255, 255, 255, 0.03);
            border-radius: 8px;
            font-size: 0.9rem;
            border-left: 3px solid var(--accent-cyan);
        }

        .object-count {
            background: rgba(0, 240, 255, 0.15);
            color: var(--accent-cyan);
            padding: 2px 8px;
            border-radius: 12px;
            font-family: 'JetBrains Mono', monospace;
            font-weight: 600;
            font-size: 0.8rem;
        }

        .empty-state {
            color: var(--text-muted);
            font-size: 0.85rem;
            text-align: center;
            padding: 1rem;
        }

        footer {
            padding: 1rem 2rem;
            text-align: center;
            font-size: 0.85rem;
            color: var(--text-muted);
            border-top: 1px solid rgba(255, 255, 255, 0.05);
        }
    </style>
</head>
<body>
    <header>
        <div class="brand">
            <div class="brand-logo">⚡</div>
            <div>
                <div class="brand-title">YOLOv8 Ultra High-FPS Engine</div>
            </div>
        </div>
        <div class="badge-fps" id="headerFps">CAMERA: 0.0 FPS | INF: 0.0 FPS</div>
    </header>

    <div class="main-container">
        <div class="viewport-card">
            <div class="viewport-wrapper">
                <video id="webcamVideo" autoplay playsinline></video>
                <canvas id="outputCanvas"></canvas>
                <div class="viewport-overlay">
                    <div class="stat-badge" id="fpsDisplay">Render FPS: 0.0</div>
                    <div class="stat-badge" id="countDisplay">Objects: 0</div>
                </div>
            </div>
        </div>

        <div class="controls-panel">
            <div class="panel-card">
                <div class="panel-title">⚡ Performance & Speed</div>
                
                <div class="control-group">
                    <label for="imgszSelect">Inference Resolution (Speed)</label>
                    <select id="imgszSelect" onchange="updateImgsz(this.value)">
                        <option value="320" selected>320px (⚡ Maximum FPS)</option>
                        <option value="480">480px (⚖️ Balanced Speed)</option>
                        <option value="640">640px (🎯 High Quality)</option>
                    </select>
                </div>

                <div class="control-group">
                    <label for="modelSelect">YOLOv8 Model Architecture</label>
                    <select id="modelSelect" onchange="updateModel(this.value)">
                        <option value="yolov8n.pt" selected>YOLOv8 Nano (Fastest)</option>
                        <option value="yolov8s.pt">YOLOv8 Small (Balanced)</option>
                        <option value="yolov8m.pt">YOLOv8 Medium (Accurate)</option>
                    </select>
                </div>

                <div class="control-group">
                    <label>
                        Confidence Threshold
                        <span class="range-value" id="confVal">35%</span>
                    </label>
                    <input type="range" id="confSlider" min="10" max="90" value="35" oninput="updateConf(this.value)">
                </div>

                <button class="btn btn-primary" onclick="toggleCamera()" id="camBtn">
                    📷 Start Camera Stream
                </button>
                <button class="btn btn-secondary" onclick="takeSnapshot()">
                    📸 Save High-Res Snapshot
                </button>
            </div>

            <div class="panel-card">
                <div class="panel-title">🎯 Active Detections</div>
                <div class="objects-list" id="objectsList">
                    <div class="empty-state">Start camera to view real-time detections.</div>
                </div>
            </div>
        </div>
    </div>

    <footer>
        Ultralytics YOLOv8 Ultra High-FPS Engine • Multi-Threaded Client-Side Canvas Rendering
    </footer>

    <script>
        const video = document.getElementById('webcamVideo');
        const canvas = document.getElementById('outputCanvas');
        const ctx = canvas.getContext('2d');
        let isStreaming = false;
        let lastRenderTime = performance.now();
        let renderFps = 0;
        let pendingInference = false;
        let activeDetections = [];
        let activeCounts = {};

        async function toggleCamera() {
            const btn = document.getElementById('camBtn');
            if (!isStreaming) {
                try {
                    const stream = await navigator.mediaDevices.getUserMedia({
                        video: { width: { ideal: 1280 }, height: { ideal: 720 }, facingMode: "user" }
                    });
                    video.srcObject = stream;
                    await video.play();

                    isStreaming = true;
                    btn.innerText = '🛑 Stop Camera Stream';
                    btn.style.background = 'linear-gradient(135deg, #ff4757, #ff6b81)';
                    
                    requestAnimationFrame(renderLoop);
                    startAsyncInferenceLoop();
                } catch (err) {
                    alert('Camera access error: ' + err.message);
                }
            } else {
                if (video.srcObject) {
                    video.srcObject.getTracks().forEach(track => track.stop());
                }
                isStreaming = false;
                btn.innerText = '📷 Start Camera Stream';
                btn.style.background = 'linear-gradient(135deg, var(--accent-cyan), #00a8ff)';
                ctx.clearRect(0, 0, canvas.width, canvas.height);
            }
        }

        // Smooth 60 FPS Render Loop
        function renderLoop() {
            if (!isStreaming) return;

            if (video.videoWidth && canvas.width !== video.videoWidth) {
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
            }

            ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Draw bounding boxes fast on client canvas
            activeDetections.forEach(det => {
                const [x1, y1, x2, y2] = det.box;
                const scaleX = canvas.width / det.orig_w;
                const scaleY = canvas.height / det.orig_h;

                const rx1 = x1 * scaleX;
                const ry1 = y1 * scaleY;
                const rw = (x2 - x1) * scaleX;
                const rh = (y2 - y1) * scaleY;

                // Box
                ctx.strokeStyle = '#00f0ff';
                ctx.lineWidth = 3;
                ctx.strokeRect(rx1, ry1, rw, rh);

                // Label background
                const labelText = `${det.label} ${(det.conf * 100).toFixed(0)}%`;
                ctx.font = '600 14px "JetBrains Mono", monospace';
                const textWidth = ctx.measureText(labelText).width;

                ctx.fillStyle = '#00f0ff';
                ctx.fillRect(rx1, ry1 - 24, textWidth + 12, 24);

                // Label text
                ctx.fillStyle = '#000000';
                ctx.fillText(labelText, rx1 + 6, ry1 - 7);
            });

            // FPS calculation
            const now = performance.now();
            renderFps = 0.9 * renderFps + 0.1 * (1000 / (now - lastRenderTime));
            lastRenderTime = now;

            document.getElementById('fpsDisplay').innerText = `Camera FPS: ${renderFps.toFixed(1)}`;
            document.getElementById('headerFps').innerText = `CAMERA: ${renderFps.toFixed(1)} FPS`;

            requestAnimationFrame(renderLoop);
        }

        // Async Background Inference Loop
        async function startAsyncInferenceLoop() {
            while (isStreaming) {
                if (video.readyState === video.HAVE_ENOUGH_DATA && !pendingInference) {
                    pendingInference = true;

                    const tempCanvas = document.createElement('canvas');
                    tempCanvas.width = 480; // Fast scale for network payload
                    tempCanvas.height = 270;
                    const tempCtx = tempCanvas.getContext('2d');
                    tempCtx.drawImage(video, 0, 0, tempCanvas.width, tempCanvas.height);
                    
                    const frameData = tempCanvas.toDataURL('image/jpeg', 0.5);

                    try {
                        const res = await fetch('/api/detect', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ image: frameData })
                        });
                        const data = await res.json();

                        if (data.detections) {
                            activeDetections = data.detections;
                            activeCounts = data.counts || {};
                            document.getElementById('countDisplay').innerText = `Objects: ${data.total || 0}`;
                            updateObjectsList(activeCounts);
                        }
                    } catch (err) {
                        console.error("Inference error:", err);
                    } finally {
                        pendingInference = false;
                    }
                }
                await new Promise(r => setTimeout(r, 20)); // ~50Hz poll
            }
        }

        function updateObjectsList(counts) {
            const container = document.getElementById('objectsList');
            const keys = Object.keys(counts);

            if (keys.length === 0) {
                container.innerHTML = '<div class="empty-state">No objects detected in current frame.</div>';
                return;
            }

            container.innerHTML = keys.map(cls => `
                <div class="object-item">
                    <span>${cls}</span>
                    <span class="object-count">${counts[cls]}</span>
                </div>
            `).join('');
        }

        function updateConf(val) {
            document.getElementById('confVal').innerText = `${val}%`;
            fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ conf: val / 100.0 })
            });
        }

        function updateImgsz(val) {
            fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ imgsz: parseInt(val) })
            });
        }

        function updateModel(modelName) {
            fetch('/api/settings', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ model: modelName })
            });
        }

        function takeSnapshot() {
            if (!isStreaming) return;
            const snapCanvas = document.createElement('canvas');
            snapCanvas.width = video.videoWidth;
            snapCanvas.height = video.videoHeight;
            const snapCtx = snapCanvas.getContext('2d');
            snapCtx.drawImage(video, 0, 0);
            
            // Draw boxes on snapshot
            activeDetections.forEach(det => {
                const [x1, y1, x2, y2] = det.box;
                const scaleX = snapCanvas.width / det.orig_w;
                const scaleY = snapCanvas.height / det.orig_h;
                snapCtx.strokeStyle = '#00f0ff';
                snapCtx.lineWidth = 4;
                snapCtx.strokeRect(x1 * scaleX, y1 * scaleY, (x2 - x1) * scaleX, (y2 - y1) * scaleY);
            });

            const link = document.createElement('a');
            link.href = snapCanvas.toDataURL('image/jpeg');
            link.download = `yolov8_highfps_${Date.now()}.jpg`;
            link.click();
        }
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/api/settings', methods=['POST'])
def update_settings():
    global model, CURRENT_MODEL_NAME, CONF_THRESHOLD, INFERENCE_IMGSZ
    data = request.json
    if 'conf' in data:
        CONF_THRESHOLD = float(data['conf'])
    if 'imgsz' in data:
        INFERENCE_IMGSZ = int(data['imgsz'])
    if 'model' in data and data['model'] != CURRENT_MODEL_NAME:
        CURRENT_MODEL_NAME = data['model']
        model = YOLO(CURRENT_MODEL_NAME)
    return jsonify({"status": "ok", "conf": CONF_THRESHOLD, "imgsz": INFERENCE_IMGSZ, "model": CURRENT_MODEL_NAME})

@app.route('/api/detect', methods=['POST'])
def detect():
    try:
        data = request.json
        image_data = data.get('image', '')
        if ',' in image_data:
            image_data = image_data.split(',')[1]

        img_bytes = base64.b64decode(image_data)
        np_arr = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if img is None:
            return jsonify({"error": "Invalid image"}), 400

        h_orig, w_orig = img.shape[:2]

        # Fast inference
        results = model.predict(
            img,
            conf=CONF_THRESHOLD,
            iou=IOU_THRESHOLD,
            imgsz=INFERENCE_IMGSZ,
            verbose=False
        )
        res = results[0]

        detections = []
        class_counts = {}
        boxes = res.boxes

        if boxes is not None and len(boxes) > 0:
            cls_ids = boxes.cls.cpu().numpy().astype(int)
            confs = boxes.conf.cpu().numpy()
            xyxy = boxes.xyxy.cpu().numpy()

            for (box, cid, cnf) in zip(xyxy, cls_ids, confs):
                cname = model.names[cid]
                class_counts[cname] = class_counts.get(cname, 0) + 1
                detections.append({
                    "box": [float(box[0]), float(box[1]), float(box[2]), float(box[3])],
                    "label": cname,
                    "conf": float(cnf),
                    "orig_w": w_orig,
                    "orig_h": h_orig
                })

        return jsonify({
            "detections": detections,
            "counts": class_counts,
            "total": len(detections)
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    print("\n========================================================")
    print(" ⚡ Launching Ultralytics YOLOv8 Ultra High-FPS Web Engine")
    print(" Server: http://localhost:5000")
    print("========================================================\n")
    app.run(host='0.0.0.0', port=5000, debug=False)
