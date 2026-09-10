"""
Ultralytics YOLOv8 Ultra High-FPS Real-Time Object Detection (Desktop OpenCV App)
Optimized with Multi-threaded Camera Capture, Async Inference, ONNX Support, and Res Tuning
"""

import sys
import time
import argparse
import threading
from pathlib import Path
import cv2
import numpy as np
import torch

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: Ultralytics package is not installed. Run: pip install ultralytics")
    sys.exit(1)

# PyTorch CPU Optimizations
torch.set_num_threads(max(1, torch.get_num_threads()))
torch.set_grad_enabled(False)


class ThreadedWebcam:
    """Fast Non-Blocking Threaded Webcam Stream"""
    def __init__(self, source=0, width=1280, height=720):
        self.cap = cv2.VideoCapture(source)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Minimal buffer lag
        
        self.ret, self.frame = self.cap.read()
        self.stopped = False
        self.lock = threading.Lock()

    def start(self):
        threading.Thread(target=self._update, daemon=True).start()
        return self

    def _update(self):
        while not self.stopped:
            ret, frame = self.cap.read()
            if not ret:
                self.stopped = True
                break
            with self.lock:
                self.ret = ret
                self.frame = frame

    def read(self):
        with self.lock:
            return self.ret, self.frame.copy() if self.frame is not None else None

    def stop(self):
        self.stopped = True
        self.cap.release()


class AsyncYOLOInference:
    """Asynchronous Background YOLOv8 Inference Engine for Maximum FPS"""
    def __init__(self, model_path="yolov8n.pt", imgsz=320, conf=0.35, iou=0.45):
        self.model_path = model_path
        self.imgsz = imgsz
        self.conf = conf
        self.iou = iou
        self.model = YOLO(model_path)
        
        self.latest_frame = None
        self.latest_results = None
        self.running = True
        self.lock = threading.Lock()
        self.new_frame_event = threading.Event()
        self.inference_fps = 0.0

    def start(self):
        threading.Thread(target=self._worker, daemon=True).start()
        return self

    def submit_frame(self, frame):
        with self.lock:
            self.latest_frame = frame
        self.new_frame_event.set()

    def _worker(self):
        prev_time = time.time()
        while self.running:
            self.new_frame_event.wait(timeout=0.1)
            self.new_frame_event.clear()
            
            with self.lock:
                frame = self.latest_frame
                
            if frame is None:
                continue

            t0 = time.time()
            results = self.model.predict(
                frame,
                conf=self.conf,
                iou=self.iou,
                imgsz=self.imgsz,
                verbose=False
            )
            t1 = time.time()
            
            # Calculate inference rate
            dt = t1 - prev_time
            if dt > 0:
                self.inference_fps = 0.8 * self.inference_fps + 0.2 * (1.0 / dt)
            prev_time = t1

            with self.lock:
                self.latest_results = results[0]

    def get_results(self):
        with self.lock:
            return self.latest_results, self.inference_fps

    def set_imgsz(self, imgsz):
        self.imgsz = imgsz
        print(f"⚡ Inference Size set to: {imgsz}px")

    def set_conf(self, conf):
        self.conf = conf
        print(f"🎯 Confidence Threshold set to: {conf:.2f}")

    def stop(self):
        self.running = False


def parse_args():
    parser = argparse.ArgumentParser(description="High-FPS YOLOv8 Real-Time Detection")
    parser.add_argument("--model", type=str, default="yolov8n.pt", help="YOLOv8 model (e.g. yolov8n.pt, yolov8s.pt, yolov8n.onnx)")
    parser.add_argument("--source", type=str, default="0", help="Camera index (e.g., 0)")
    parser.add_argument("--conf", type=float, default=0.35, help="Confidence threshold")
    parser.add_argument("--imgsz", type=int, default=320, help="Inference resolution (320=Max FPS, 480=Balanced, 640=Quality)")
    return parser.parse_args()


def main():
    args = parse_args()
    source = int(args.source) if args.source.isdigit() else args.source

    print(f"\n========================================================")
    print(f" 🚀 Ultralytics YOLOv8 ULTRA HIGH-FPS Real-Time Vision")
    print(f" Model: {args.model}")
    print(f" Inference Res: {args.imgsz}px (Change with keys 1, 2, 3)")
    print(f" Initial Conf: {args.conf}")
    print(f"========================================================\n")
    print("Interactive Hotkeys:")
    print(" [1] Max Speed Mode (320px inference)")
    print(" [2] Balanced Speed Mode (480px inference)")
    print(" [3] High Accuracy Mode (640px inference)")
    print(" [+] / [-] Increase / Decrease confidence threshold")
    print(" [s] Save snapshot frame")
    print(" [q] Exit application")
    print("========================================================\n")

    # Start non-blocking webcam stream
    webcam = ThreadedWebcam(source=source).start()
    time.sleep(0.5)

    # Check frame availability
    ret, frame = webcam.read()
    if not ret or frame is None:
        print(f"Error: Unable to access camera source {source}")
        webcam.stop()
        sys.exit(1)

    # Start Async YOLO Inference Engine
    print("Loading YOLOv8 Engine...")
    engine = AsyncYOLOInference(model_path=args.model, imgsz=args.imgsz, conf=args.conf).start()

    snapshot_dir = Path("snapshots")
    snapshot_dir.mkdir(exist_ok=True)

    window_name = "Ultralytics YOLOv8 - High FPS Real-Time Vision"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1280, 720)

    render_prev_time = time.time()
    render_fps = 0.0
    latest_boxes_draw = []
    latest_class_counts = {}

    while True:
        ret, frame = webcam.read()
        if not ret or frame is None:
            break

        # Calculate Display Render FPS
        curr_time = time.time()
        dt = curr_time - render_prev_time
        if dt > 0:
            render_fps = 0.9 * render_fps + 0.1 * (1.0 / dt)
        render_prev_time = curr_time

        # Submit latest frame to background inference engine
        engine.submit_frame(frame)

        # Get latest completed inference results
        res, inf_fps = engine.get_results()

        annotated_frame = frame.copy()

        if res is not None:
            boxes = res.boxes
            if boxes is not None and len(boxes) > 0:
                cls_ids = boxes.cls.cpu().numpy().astype(int)
                confs = boxes.conf.cpu().numpy()
                xyxy = boxes.xyxy.cpu().numpy().astype(int)
                names = res.names

                latest_class_counts = {}
                latest_boxes_draw = []

                for (box, cid, cnf) in zip(xyxy, cls_ids, confs):
                    cname = names[cid]
                    latest_class_counts[cname] = latest_class_counts.get(cname, 0) + 1
                    latest_boxes_draw.append((box, cname, cnf))

        # Fast direct drawing of bounding boxes
        for (box, cname, cnf) in latest_boxes_draw:
            x1, y1, x2, y2 = box
            # Sleek Cyber Neon Bounding Box
            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), (0, 240, 255), 2, cv2.LINE_AA)
            
            # Label banner
            label = f"{cname} {cnf:.2f}"
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            cv2.rectangle(annotated_frame, (x1, y1 - 22), (x1 + w + 10, y1), (0, 240, 255), -1)
            cv2.putText(annotated_frame, label, (x1 + 5, y1 - 6), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1, cv2.LINE_AA)

        # Draw HUD Header Banner
        h_img, w_img, _ = annotated_frame.shape
        overlay = annotated_frame.copy()
        cv2.rectangle(overlay, (0, 0), (w_img, 60), (10, 12, 18), -1)
        cv2.addWeighted(overlay, 0.8, annotated_frame, 0.2, 0, annotated_frame)

        # FPS Badges
        hud_text = f"CAMERA DISPLAY: {render_fps:.1f} FPS  |  YOLO INFERENCE: {inf_fps:.1f} FPS  |  Res: {engine.imgsz}px  |  Conf: {engine.conf:.2f}"
        cv2.putText(annotated_frame, hud_text, (20, 38), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 255, 200), 2, cv2.LINE_AA)

        # Left Objects Panel
        if latest_class_counts:
            panel_y = h_img - 25 - (len(latest_class_counts) * 22)
            cv2.rectangle(annotated_frame, (15, panel_y - 25), (320, h_img - 15), (15, 18, 25), -1)
            cv2.rectangle(annotated_frame, (15, panel_y - 25), (320, h_img - 15), (0, 240, 255), 1)
            cv2.putText(annotated_frame, f"Detected ({sum(latest_class_counts.values())} total):", (25, panel_y - 8),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1, cv2.LINE_AA)

            curr_y = panel_y + 15
            for cname, cnt in list(latest_class_counts.items())[:6]:
                txt = f"  • {cname}: {cnt}"
                cv2.putText(annotated_frame, txt, (25, curr_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 230, 255), 1, cv2.LINE_AA)
                curr_y += 20

        # Show Window
        cv2.imshow(window_name, annotated_frame)

        # Hotkeys
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('1'):
            engine.set_imgsz(320)
        elif key == ord('2'):
            engine.set_imgsz(480)
        elif key == ord('3'):
            engine.set_imgsz(640)
        elif key == ord('+') or key == ord('='):
            engine.set_conf(min(0.95, engine.conf + 0.05))
        elif key == ord('-') or key == ord('_'):
            engine.set_conf(max(0.05, engine.conf - 0.05))
        elif key == ord('s'):
            snap_path = snapshot_dir / f"highfps_snapshot_{int(time.time())}.jpg"
            cv2.imwrite(str(snap_path), annotated_frame)
            print(f"📸 Saved snapshot to {snap_path}")

    engine.stop()
    webcam.stop()
    cv2.destroyAllWindows()
    print("Application stopped.")


if __name__ == "__main__":
    main()
