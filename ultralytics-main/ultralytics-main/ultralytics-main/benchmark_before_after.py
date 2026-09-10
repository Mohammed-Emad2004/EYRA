"""
Benchmark Before/After — YOLOv8 Assistive Detection
Compares yolov8n (v1 config) vs yolov8s (v2 config) on the included bus.jpg
and any snapshots available in the snapshots/ directory.

Run: python benchmark_before_after.py
"""

import time
import sys
from pathlib import Path
import cv2
import numpy as np

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: pip install ultralytics")
    sys.exit(1)

IMAGES = [Path("bus.jpg")] + sorted(Path("snapshots").glob("*.jpg"))[:4]
IMAGES = [p for p in IMAGES if p.exists()]

if not IMAGES:
    print("No test images found. Run from the ultralytics-main directory.")
    sys.exit(1)

# ── Config comparison ─────────────────────────────────────────────────────────
CONFIGS = [
    {
        "label": "v1.0 — yolov8n / 320px / conf=0.35",
        "model": "yolov8n.pt",
        "imgsz": 320,
        "conf": 0.35,
        "iou": 0.45,
    },
    {
        "label": "v2.0 — yolov8s / 480px / conf=0.30",
        "model": "yolov8s.pt",
        "imgsz": 480,
        "conf": 0.30,
        "iou": 0.50,
    },
]

REPS = 5  # Inference repetitions per image for stable timing


def run_benchmark(cfg: dict):
    print(f"\n{'='*62}")
    print(f"  {cfg['label']}")
    print(f"{'='*62}")

    model = YOLO(cfg["model"])

    total_latency = []
    total_detections = []
    all_confs = []

    for img_path in IMAGES:
        img = cv2.imread(str(img_path))
        if img is None:
            continue

        # Warm-up
        model.predict(img, imgsz=cfg["imgsz"], conf=cfg["conf"],
                      iou=cfg["iou"], verbose=False)

        times = []
        det_counts = []
        conf_vals = []

        for _ in range(REPS):
            t0 = time.perf_counter()
            results = model.predict(img, imgsz=cfg["imgsz"], conf=cfg["conf"],
                                    iou=cfg["iou"], verbose=False)
            elapsed = time.perf_counter() - t0
            times.append(elapsed)

            res = results[0]
            n = len(res.boxes) if res.boxes is not None else 0
            det_counts.append(n)
            if res.boxes is not None and n > 0:
                confs = res.boxes.conf.cpu().numpy().tolist()
                conf_vals.extend(confs)

        avg_ms = (sum(times) / len(times)) * 1000
        avg_fps = 1000 / avg_ms
        avg_dets = sum(det_counts) / len(det_counts)

        total_latency.append(avg_ms)
        total_detections.append(avg_dets)
        all_confs.extend(conf_vals)

        print(f"\n  📷 {img_path.name} ({img.shape[1]}×{img.shape[0]})")
        print(f"     Latency  : {avg_ms:.1f} ms  ({avg_fps:.1f} FPS)")
        print(f"     Detections: {avg_dets:.1f} avg over {REPS} runs")
        if conf_vals:
            print(f"     Conf range: {min(conf_vals):.2f} – {max(conf_vals):.2f}  "
                  f"(avg {sum(conf_vals)/len(conf_vals):.2f})")

        # Print individual detections from last run
        res = model.predict(img, imgsz=cfg["imgsz"], conf=cfg["conf"],
                            iou=cfg["iou"], verbose=False)[0]
        if res.boxes is not None and len(res.boxes) > 0:
            cls_ids = res.boxes.cls.cpu().numpy().astype(int)
            confs_arr = res.boxes.conf.cpu().numpy()
            for cid, cnf in sorted(zip(cls_ids, confs_arr),
                                   key=lambda x: -x[1])[:8]:
                print(f"       • {model.names[cid]:20s}  conf={cnf:.3f}")

    print(f"\n  ── OVERALL SUMMARY ──────────────────────────────────")
    if total_latency:
        print(f"  Avg Latency   : {sum(total_latency)/len(total_latency):.1f} ms")
        print(f"  Avg Inference : {1000/(sum(total_latency)/len(total_latency)):.1f} FPS")
        print(f"  Avg Detections: {sum(total_detections)/len(total_detections):.1f} per frame")
    if all_confs:
        print(f"  Avg Confidence: {sum(all_confs)/len(all_confs):.3f}")
        print(f"  Min Confidence: {min(all_confs):.3f}")
        print(f"  Max Confidence: {max(all_confs):.3f}")


if __name__ == "__main__":
    print("\n🔬 YOLOv8 Assistive Detection — Before / After Benchmark")
    print(f"   Test images: {[p.name for p in IMAGES]}\n")

    for cfg in CONFIGS:
        run_benchmark(cfg)

    print("\n\n✅ Benchmark complete.")
    print("   Higher detections + higher avg confidence = better accuracy.")
    print("   Lower latency = better real-time performance.\n")
