"""
Test Ultralytics YOLOv8 Object Detection on Sample Image
"""

import sys
from pathlib import Path

def main():
    try:
        from ultralytics import YOLO
    except ImportError:
        print("Error: Ultralytics is not installed yet.")
        sys.exit(1)

    print("🚀 Initializing YOLOv8 Model (yolov8n.pt)...")
    model = YOLO("yolov8n.pt")

    sample_url = "https://ultralytics.com/images/bus.jpg"
    print(f"📥 Running inference on sample image: {sample_url}")

    results = model.predict(source=sample_url, conf=0.25, save=True)

    print("\n✅ Detection Completed Successfully!")
    for i, res in enumerate(results):
        print(f"  Result {i+1}: Found {len(res.boxes)} objects")
        if res.save_dir:
            print(f"  Saved output to: {res.save_dir}")

        cls_ids = res.boxes.cls.cpu().numpy().astype(int)
        confs = res.boxes.conf.cpu().numpy()
        for cid, cnf in zip(cls_ids, confs):
            print(f"   • {model.names[cid]}: {cnf:.2f}")

if __name__ == "__main__":
    main()
