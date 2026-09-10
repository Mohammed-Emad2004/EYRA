"""
Ultralytics YOLOv8 Ultra High-FPS Real-Time Object Detection
with Distance Estimation (Meters) and Spatial Direction (Left / Center / Right)
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

# Average real-world widths of common COCO objects (in meters)
REAL_WORLD_WIDTHS = {
    "person": 0.48,
    "car": 1.85,
    "bus": 2.60,
    "truck": 2.50,
    "bicycle": 0.60,
    "motorcycle": 0.80,
    "dog": 0.35,
    "cat": 0.25,
    "chair": 0.50,
    "couch": 1.80,
    "potted plant": 0.35,
    "tv": 0.90,
    "laptop": 0.35,
    "mouse": 0.10,
    "keyboard": 0.45,
    "cell phone": 0.08,
    "bottle": 0.08,
    "cup": 0.08,
    "book": 0.20,
    "backpack": 0.40,
    "umbrella": 0.80,
}
DEFAULT_REAL_WIDTH = 0.40  # Default 40cm width for unlisted objects
DEFAULT_FOCAL_LENGTH = 900  # Default camera focal length in pixels for ~60° FOV at 720p


def estimate_distance_and_direction(x1, y1, x2, y2, cname, frame_width, focal_length=900):
    box_w = max(1, x2 - x1)
    real_w = REAL_WORLD_WIDTHS.get(cname.lower(), DEFAULT_REAL_WIDTH)

    # Distance calculation: D = (W_real * f) / w_pixels
    distance_m = (real_w * focal_length) / box_w

    # Horizontal center of object box
    box_cx = (x1 + x2) / 2.0
    norm_x = box_cx / frame_width

    # Spatial direction & sector alignment
    if norm_x < 0.40:
        offset_pct = int((0.50 - norm_x) * 100)
        direction = f"Left ({offset_pct}%)"
        dir_tag = "LEFT"
    elif norm_x > 0.60:
        offset_pct = int((norm_x - 0.50) * 100)
        direction = f"Right ({offset_pct}%)"
        dir_tag = "RIGHT"
    else:
        direction = "Center"
        dir_tag = "CENTER"

    return round(distance_m, 2), direction, dir_tag


class ThreadedWebcam:
    """Fast Non-Blocking Threaded Webcam Stream"""
    def __init__(self, source=0, width=1280, height=720):
        self.cap = cv2.VideoCapture(source)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
        self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

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
    """Asynchronous Background YOLOv8 Inference Engine"""
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
    parser = argparse.ArgumentParser(description="YOLOv8 Object Detection with Distance & Direction")
    parser.add_argument("--model", type=str, default="yolov8n.pt", help="YOLOv8 model file")
    parser.add_argument("--source", type=str, default="0", help="Camera index")
    parser.add_argument("--conf", type=float, default=0.35, help="Confidence threshold")
    parser.add_argument("--imgsz", type=int, default=320, help="Inference resolution")
    parser.add_argument("--focal", type=float, default=900, help="Camera focal length calibration")
    return parser.parse_args()


def main():
    args = parse_args()
    source = int(args.source) if args.source.isdigit() else args.source
    focal_length = args.focal

    print(f"\n========================================================")
    print(f" 🚀 YOLOv8 Distance & Direction Spatial Detection")
    print(f" Model: {args.model}")
    print(f" Focal Length: {focal_length}px")
    print(f"========================================================\n")
    print("Features & Controls:")
    print(" • Distance Estimation in meters (m)")
    print(" • Direction Identification (Left / Center / Right)")
    print(" [1] 320px Speed | [2] 480px Balanced | [3] 640px Quality")
    print(" [+] / [-] Increase / Decrease confidence threshold")
    print(" [s] Save snapshot frame")
    print(" [q] Exit application")
    print("========================================================\n")

    webcam = ThreadedWebcam(source=source).start()
    time.sleep(0.5)

    ret, frame = webcam.read()
    if not ret or frame is None:
        print(f"Error: Unable to access camera source {source}")
        webcam.stop()
        sys.exit(1)

    print("Loading YOLOv8 Engine...")
    engine = AsyncYOLOInference(model_path=args.model, imgsz=args.imgsz, conf=args.conf).start()

    snapshot_dir = Path("snapshots")
    snapshot_dir.mkdir(exist_ok=True)

    window_name = "Ultralytics YOLOv8 - Distance & Direction Detection"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1280, 720)

    render_prev_time = time.time()
    render_fps = 0.0
    latest_detections = []

    while True:
        ret, frame = webcam.read()
        if not ret or frame is None:
            break

        frame_h, frame_w, _ = frame.shape

        # Calculate Display Render FPS
        curr_time = time.time()
        dt = curr_time - render_prev_time
        if dt > 0:
            render_fps = 0.9 * render_fps + 0.1 * (1.0 / dt)
        render_prev_time = curr_time

        # Submit latest frame
        engine.submit_frame(frame)

        # Get latest inference results
        res, inf_fps = engine.get_results()

        annotated_frame = frame.copy()

        # Draw subtle vertical spatial sector guides (Left / Center / Right)
        x_left_guide = int(frame_w * 0.40)
        x_right_guide = int(frame_w * 0.60)

        cv2.line(annotated_frame, (x_left_guide, 60), (x_left_guide, frame_h), (255, 255, 255), 1, cv2.LINE_AA)
        cv2.line(annotated_frame, (x_right_guide, 60), (x_right_guide, frame_h), (255, 255, 255), 1, cv2.LINE_AA)

        cv2.putText(annotated_frame, "LEFT", (30, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 180, 180), 1, cv2.LINE_AA)
        cv2.putText(annotated_frame, "CENTER", (x_left_guide + 20, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 180, 180), 1, cv2.LINE_AA)
        cv2.putText(annotated_frame, "RIGHT", (x_right_guide + 20, 85), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (180, 180, 180), 1, cv2.LINE_AA)

        if res is not None:
            boxes = res.boxes
            if boxes is not None and len(boxes) > 0:
                cls_ids = boxes.cls.cpu().numpy().astype(int)
                confs = boxes.conf.cpu().numpy()
                xyxy = boxes.xyxy.cpu().numpy().astype(int)
                names = res.names

                latest_detections = []
                for (box, cid, cnf) in zip(xyxy, cls_ids, confs):
                    cname = names[cid]
                    dist_m, direction, dir_tag = estimate_distance_and_direction(
                        box[0], box[1], box[2], box[3], cname, frame_w, focal_length
                    )
                    latest_detections.append({
                        "box": box,
                        "cname": cname,
                        "conf": cnf,
                        "distance": dist_m,
                        "direction": direction,
                        "dir_tag": dir_tag
                    })

        # Sort detections by distance (closest first)
        latest_detections.sort(key=lambda d: d["distance"])
        nearest_obj = latest_detections[0] if latest_detections else None

        # Draw detected objects with Distance and Direction
        for det in latest_detections:
            x1, y1, x2, y2 = det["box"]
            cname = det["cname"]
            cnf = det["conf"]
            dist_m = det["distance"]
            direction = det["direction"]

            # Color coding based on distance
            if dist_m < 1.0:
                box_color = (0, 0, 255)  # Alert Red (<1.0m)
                tag_bg = (0, 0, 255)
            elif dist_m < 2.5:
                box_color = (0, 240, 255)  # Cyan (1.0m - 2.5m)
                tag_bg = (0, 200, 240)
            else:
                box_color = (0, 255, 120)  # Green (>2.5m)
                tag_bg = (0, 200, 100)

            # Draw bounding box
            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2), box_color, 2, cv2.LINE_AA)

            # Draw center point dot & connection line
            cx, cy = int((x1 + x2) / 2), int((y1 + y2) / 2)
            cv2.circle(annotated_frame, (cx, cy), 5, (255, 255, 255), -1)

            # Label string: "Person | 1.85m | Left (15%)"
            label = f"{cname} | {dist_m:.2f}m | {direction}"
            (w, h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)

            # Top label box
            cv2.rectangle(annotated_frame, (x1, y1 - 24), (x1 + w + 12, y1), tag_bg, -1)
            cv2.putText(annotated_frame, label, (x1 + 6, y1 - 7), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1, cv2.LINE_AA)

        # Draw HUD Top Banner
        overlay = annotated_frame.copy()
        cv2.rectangle(overlay, (0, 0), (frame_w, 60), (10, 12, 18), -1)
        cv2.addWeighted(overlay, 0.85, annotated_frame, 0.15, 0, annotated_frame)

        hud_text = f"FPS: {render_fps:.1f}  |  INFERENCE: {inf_fps:.1f} FPS  |  Res: {engine.imgsz}px  |  Conf: {engine.conf:.2f}"
        cv2.putText(annotated_frame, hud_text, (20, 38), cv2.FONT_HERSHEY_SIMPLEX, 0.65, (0, 255, 200), 2, cv2.LINE_AA)

        # Nearest Object Alert Bar (Bottom-Left Panel)
        if nearest_obj:
            n_name = nearest_obj["cname"]
            n_dist = nearest_obj["distance"]
            n_dir = nearest_obj["direction"]

            panel_y = frame_h - 100
            cv2.rectangle(annotated_frame, (15, panel_y), (420, frame_h - 15), (15, 18, 25), -1)
            cv2.rectangle(annotated_frame, (15, panel_y), (420, frame_h - 15), (0, 240, 255), 1)

            cv2.putText(annotated_frame, "NEAREST OBJECT ALERT:", (25, panel_y + 25),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, (255, 255, 255), 1, cv2.LINE_AA)

            alert_txt = f"• {n_name.upper()} at {n_dist:.2f} meters [{n_dir}]"
            alert_color = (0, 0, 255) if n_dist < 1.0 else (0, 240, 255)
            cv2.putText(annotated_frame, alert_txt, (25, panel_y + 55),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, alert_color, 2, cv2.LINE_AA)

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
            snap_path = snapshot_dir / f"distance_snapshot_{int(time.time())}.jpg"
            cv2.imwrite(str(snap_path), annotated_frame)
            print(f"📸 Saved snapshot to {snap_path}")

    engine.stop()
    webcam.stop()
    cv2.destroyAllWindows()
    print("Application stopped.")


if __name__ == "__main__":
    main()
