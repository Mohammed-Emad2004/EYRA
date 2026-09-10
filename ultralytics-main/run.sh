#!/usr/bin/env bash
# ============================================================
#  Assistive YOLOv8 eSpeak - One-Click Runner (Linux / macOS)
#  Edit the variables below to change model or image size.
# ============================================================

# --- Configurable arguments (edit these) ---
MODEL="yolov8s.pt"
IMGSZ="480"

# --- Resolved script directory (three-level nesting) ---
SCRIPT_DIR="$(cd "$(dirname "$0")/ultralytics-main/ultralytics-main" && pwd)"

echo ""
echo "  [Assistive Vision] Starting with model=${MODEL}  imgsz=${IMGSZ}"
echo "  Working directory: ${SCRIPT_DIR}"
echo ""

cd "${SCRIPT_DIR}" || { echo "ERROR: Could not cd to ${SCRIPT_DIR}"; exit 1; }
python assistive_yolov8_espeak.py --model "${MODEL}" --imgsz "${IMGSZ}"
