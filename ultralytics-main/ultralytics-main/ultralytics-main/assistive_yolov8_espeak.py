"""
Real-Time Assistive Object Detection System for Visually Impaired Users
YOLOv8s + ByteTrack + eSpeak NG Arabic Voice Warnings
Distance & Spatial Position Analysis — v3.0 (Multi-Object Grouped Announcements)

v3.0 Changes over v2.0:
  10. Multi-object grouping: all center objects grouped into ONE Arabic sentence
  11. Arabic pluralization: dual/plural forms for common COCO classes
  12. Overlap-based center detection: bbox overlap ratio vs center zone, not just center point
  13. Temporal group change detection: announce only when the object group actually changes
  14. TTS queue draining: old stale messages discarded, only newest message kept
  15. Priority-sorted announcements: high-danger objects listed first in the sentence
  16. Configurable constants: CENTER_ZONE_WIDTH, CENTER_OVERLAP_THRESHOLD, TTS_COOLDOWN etc.

Preserved from v2.0:
  - yolov8s default, ByteTrack tracking, CLAHE preprocessing
  - Multi-metric distance estimation, approach detection
  - Threaded webcam, async YOLO inference, async TTS engine
  - All hotkeys, HUD, snapshot, mute
"""

import os
import sys
import time
import queue
import argparse
import threading
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
import cv2
import numpy as np
import torch

try:
    from ultralytics import YOLO
except ImportError:
    print("Error: Ultralytics package is not installed. Run: pip install ultralytics")
    sys.exit(1)

# ── PyTorch CPU Optimizations ─────────────────────────────────────────────────
torch.set_num_threads(max(1, torch.get_num_threads()))
torch.set_grad_enabled(False)

# ── Optional pygame/gTTS fallback ─────────────────────────────────────────────
HAS_PYGAME = False
try:
    import pygame
    from gtts import gTTS
    pygame.mixer.init()
    HAS_PYGAME = True
except Exception:
    HAS_PYGAME = False


# =============================================================================
#  CONFIGURATION — all tuneable parameters in one place (Requirement #20)
# =============================================================================

# ── Detection ────────────────────────────────────────────────────────────────
CONF_THRESHOLD = 0.30           # YOLO confidence threshold
IOU_THRESHOLD = 0.50            # YOLO NMS IoU threshold
IMAGE_SIZE = 480                # Inference resolution in pixels

# ── Center zone (Requirement #1) ─────────────────────────────────────────────
#  CENTER_ZONE_WIDTH: fraction of frame width that counts as "center".
#    0.40 means the center 40% of the frame (from 30% to 70%).
#  CENTER_OVERLAP_THRESHOLD: minimum fraction of a bbox that must overlap
#    the center zone for the object to be considered "in front".
CENTER_ZONE_WIDTH = 0.40
CENTER_OVERLAP_THRESHOLD = 0.20

# ── TTS / announcement (Requirements #9, #10, #15) ──────────────────────────
TTS_COOLDOWN = 3.0              # Seconds between repeated announcements
ENABLE_MULTI_OBJECT_ANNOUNCEMENT = True
ENABLE_ARABIC_PLURALIZATION = True
ENABLE_TEMPORAL_GROUPING = True

# ── Feature toggles ─────────────────────────────────────────────────────────
DEFAULT_DANGER_DISTANCE = 1.8   # metres
DEFAULT_FOCAL_LENGTH = 900      # pixels, ~60° FOV @ 720p

# ── Safety-relevant object classes (only these trigger processing) ───────────
IMPORTANT_CLASSES = {
    "person", "bicycle", "car", "motorcycle", "bus", "truck",
    "chair", "couch", "dining table", "bench", "bed",
    "dog", "cat", "potted plant", "bottle", "suitcase",
    "traffic light", "stop sign", "fire hydrant", "backpack",
    "knife", "scissors", "umbrella",
}

# ── Object priority (Requirement #7) — higher = announced first ─────────────
OBJECT_PRIORITY = {
    "person": 100,
    "car": 95, "truck": 95, "bus": 95,
    "motorcycle": 90, "bicycle": 85,
    "dog": 80, "cat": 75,
    "knife": 70, "scissors": 70,
    "traffic light": 65, "stop sign": 65, "fire hydrant": 65,
    "chair": 50, "dining table": 45, "bench": 45, "couch": 45, "bed": 40,
    "bottle": 35, "suitcase": 35, "backpack": 35,
    "potted plant": 30, "umbrella": 30,
}
_DEFAULT_PRIORITY = 20


# =============================================================================
#  ARABIC LANGUAGE LAYER (Requirements #4, #5, #6, #16)
# =============================================================================

# ── Arabic singular names (Requirement #4) ───────────────────────────────────
ARABIC_OBJECT_NAMES = {
    "person": "شخص",
    "bicycle": "دراجة",
    "car": "سيارة",
    "motorcycle": "دراجة نارية",
    "airplane": "طائرة",
    "bus": "حافلة",
    "train": "قطار",
    "truck": "شاحنة",
    "boat": "قارب",
    "traffic light": "إشارة مرور",
    "fire hydrant": "صنبور إطفاء",
    "stop sign": "إشارة توقف",
    "parking meter": "عداد مواقف",
    "bench": "مقعد",
    "bird": "طائر",
    "cat": "قطة",
    "dog": "كلب",
    "horse": "حصان",
    "sheep": "خروف",
    "cow": "بقرة",
    "elephant": "فيل",
    "bear": "دب",
    "zebra": "حمار وحشي",
    "giraffe": "زرافة",
    "backpack": "حقيبة ظهر",
    "umbrella": "مظلة",
    "handbag": "حقيبة يد",
    "tie": "ربطة عنق",
    "suitcase": "حقيبة سفر",
    "frisbee": "قرص طائر",
    "skis": "زلاجات",
    "snowboard": "لوح ثلج",
    "sports ball": "كرة قدم",
    "kite": "طائرة ورقية",
    "baseball bat": "مضرب",
    "baseball glove": "قفاز",
    "skateboard": "لوح تزلج",
    "surfboard": "لوح ركوب أمواج",
    "tennis racket": "مضرب تنس",
    "bottle": "زجاجة",
    "wine glass": "كأس",
    "cup": "كوب",
    "fork": "شوكة",
    "knife": "سكين",
    "spoon": "ملعقة",
    "bowl": "وعاء",
    "banana": "موزة",
    "apple": "تفاحة",
    "sandwich": "شطيرة",
    "orange": "برتقالة",
    "broccoli": "بروكلي",
    "carrot": "جزرة",
    "hot dog": "هوت دوج",
    "pizza": "بيتزا",
    "donut": "دونات",
    "cake": "كعكة",
    "chair": "كرسي",
    "couch": "أريكة",
    "potted plant": "نبتة",
    "bed": "سرير",
    "dining table": "طاولة طعام",
    "toilet": "حمام",
    "tv": "تلفاز",
    "laptop": "حاسوب محمول",
    "mouse": "فأرة",
    "remote": "جهاز تحكم",
    "keyboard": "لوحة مفاتيح",
    "cell phone": "هاتف محمول",
    "microwave": "ميكروويف",
    "oven": "فرن",
    "toaster": "محمصة",
    "sink": "حوض",
    "refrigerator": "ثلاجة",
    "book": "كتاب",
    "clock": "ساعة",
    "vase": "زهريّة",
    "scissors": "مقص",
    "teddy bear": "دب لعبة",
    "hair drier": "مجفف شعر",
    "toothbrush": "فرشاة أسنان",
}

# ── Arabic plural forms (Requirement #5) ─────────────────────────────────────
#  Each entry maps class_name -> (dual_form, plural_form)
#  dual = exactly 2;  plural = 3-10 (or generic ≥3)
ARABIC_PLURAL_FORMS = {
    "person":        ("شخصان",       "أشخاص"),
    "car":           ("سيارتان",     "سيارات"),
    "truck":         ("شاحنتان",     "شاحنات"),
    "bus":           ("حافلتان",     "حافلات"),
    "bicycle":       ("دراجتان",     "دراجات"),
    "motorcycle":    ("دراجتان ناريتان", "دراجات نارية"),
    "chair":         ("كرسيان",      "كراسي"),
    "dining table":  ("طاولتان",     "طاولات"),
    "bench":         ("مقعدان",      "مقاعد"),
    "dog":           ("كلبان",       "كلاب"),
    "cat":           ("قطتان",       "قطط"),
    "bottle":        ("زجاجتان",     "زجاجات"),
    "couch":         ("أريكتان",     "أرائك"),
    "bed":           ("سريران",      "أسرّة"),
    "suitcase":      ("حقيبتان",     "حقائب"),
    "backpack":      ("حقيبتان",     "حقائب ظهر"),
    "knife":         ("سكينان",      "سكاكين"),
    "scissors":      ("مقصان",       "مقصات"),
    "umbrella":      ("مظلتان",      "مظلات"),
    "potted plant":  ("نبتتان",      "نبتات"),
    "traffic light": ("إشارتا مرور", "إشارات مرور"),
    "stop sign":     ("إشارتا توقف", "إشارات توقف"),
    "fire hydrant":  ("صنبوران",     "صنابير إطفاء"),
}


def generate_arabic_object_phrase(cname: str, count: int) -> str:
    """
    Generate a natural Arabic count+noun phrase for a single class.
    Requirement #5 — Arabic pluralization layer.

    Rules:
      count=1 → singular (شخص)
      count=2 → dual form (شخصان) if available
      count=3-10 → number + plural (3 أشخاص)
      count>10 → number + singular (11 شخص) — MSA grammar

    Fallback for classes without plural forms:
      count=2 → "2 <singular>"
      count≥3 → "<N> من نوع <singular>"  — safe grammatical structure
    """
    singular = ARABIC_OBJECT_NAMES.get(cname, cname)

    if count == 1:
        return singular

    if not ENABLE_ARABIC_PLURALIZATION:
        # Feature disabled: just use number + singular
        return f"{count} {singular}"

    forms = ARABIC_PLURAL_FORMS.get(cname)

    if count == 2:
        if forms:
            return forms[0]  # dual
        return f"{singular} 2"  # fallback: "سيارة 2"  — not perfect but safe

    # count >= 3
    if forms:
        plural = forms[1]
        if count <= 10:
            return f"{count} {plural}"    # "3 أشخاص"
        else:
            return f"{count} {singular}"  # "11 شخص" — MSA rule
    else:
        # No plural form registered — safe fallback
        return f"{count} من نوع {singular}"


def group_objects_by_class(object_names: list[str]) -> dict[str, int]:
    """
    Requirement #2 — Group a list of class names into {class: count}.
    Example: ["person", "person", "car"] → {"person": 2, "car": 1}
    """
    return dict(Counter(object_names))


def sort_objects_by_priority(class_counts: dict[str, int]) -> list[tuple[str, int]]:
    """
    Requirement #7 — Sort grouped classes by descending priority.
    Returns list of (class_name, count) tuples.
    """
    return sorted(
        class_counts.items(),
        key=lambda x: OBJECT_PRIORITY.get(x[0], _DEFAULT_PRIORITY),
        reverse=True,
    )


def generate_arabic_multi_object_message(object_names: list[str]) -> str:
    """
    Requirement #6 — Master message generator.

    Input:  ["person", "person", "car", "chair"]
    Output: "يوجد شخصان وسيارة وكرسي أمامك"

    Input:  ["person"]
    Output: "شخص أمامك"
    """
    if not object_names:
        return ""

    counts = group_objects_by_class(object_names)
    sorted_items = sort_objects_by_priority(counts)

    phrases = [generate_arabic_object_phrase(cname, cnt) for cname, cnt in sorted_items]

    total_objects = sum(counts.values())
    total_classes = len(counts)

    if total_objects == 1 and total_classes == 1:
        # Single object, single class → simple form  (Requirement #17)
        # "شخص أمامك"
        return f"{phrases[0]} أمامك"
    else:
        # Multiple objects/classes → "يوجد X وY وZ أمامك"  (Requirement #18)
        joined = " و".join(phrases)
        return f"يوجد {joined} أمامك"


# =============================================================================
#  CENTER ZONE — Overlap-based detection (Requirement #1)
# =============================================================================

def compute_center_overlap(x1: int, x2: int, frame_w: int) -> float:
    """
    Compute the fraction of a bounding box's width that overlaps
    the center zone of the frame.

    The center zone spans from:
        left_edge  = frame_w * (0.5 - CENTER_ZONE_WIDTH/2)
        right_edge = frame_w * (0.5 + CENTER_ZONE_WIDTH/2)

    Returns a float in [0.0, 1.0].
    """
    zone_left = frame_w * (0.5 - CENTER_ZONE_WIDTH / 2.0)
    zone_right = frame_w * (0.5 + CENTER_ZONE_WIDTH / 2.0)

    overlap_left = max(x1, zone_left)
    overlap_right = min(x2, zone_right)
    overlap_width = max(0.0, overlap_right - overlap_left)

    box_width = max(1, x2 - x1)
    return overlap_width / box_width


def is_in_center_zone(x1: int, x2: int, frame_w: int) -> bool:
    """
    Requirement #1 — True if the bbox overlaps the center zone
    by at least CENTER_OVERLAP_THRESHOLD.
    """
    return compute_center_overlap(x1, x2, frame_w) >= CENTER_OVERLAP_THRESHOLD


def get_position_label(x1: int, x2: int, frame_w: int) -> str:
    """Return LEFT / CENTER / RIGHT.  Uses overlap for CENTER, center-point for sides."""
    if is_in_center_zone(x1, x2, frame_w):
        return "CENTER"
    mid = (x1 + x2) / 2.0
    if mid < frame_w * 0.5:
        return "LEFT"
    return "RIGHT"


# =============================================================================
#  TEMPORAL GROUP CHANGE DETECTION (Requirements #10, #11)
# =============================================================================

def make_group_signature(object_names: list[str]) -> tuple:
    """
    Requirement #11 — Create a hashable, stable representation of the
    current detection group for comparison with the previous announcement.

    Returns a tuple of (class_name, count) sorted by priority.
    Example: (("person", 2), ("car", 1))
    """
    counts = group_objects_by_class(object_names)
    return tuple(sort_objects_by_priority(counts))


def should_announce(current_sig: tuple, last_sig: tuple,
                    last_time: float, now: float,
                    cooldown: float) -> bool:
    """
    Requirement #10 — Decide whether a new announcement should fire.

    Announce when:
      1. The group changed (new object appeared, count changed, object left), OR
      2. The cooldown expired AND the same group is still present (periodic reminder).

    Do NOT announce when:
      - Same group and cooldown not expired.
    """
    if not ENABLE_TEMPORAL_GROUPING:
        # Feature disabled: always announce if cooldown passed
        return (now - last_time) >= cooldown

    if current_sig != last_sig:
        # Group changed — announce immediately (but respect a tiny 0.3s debounce
        # to avoid rapid flickering from 1-frame glitches)
        return (now - last_time) >= 0.3

    # Same group — only re-announce after full cooldown
    return (now - last_time) >= cooldown


# =============================================================================
#  REAL-WORLD SIZES & DISTANCE (preserved from v2.0)
# =============================================================================

REAL_WORLD_WIDTHS = {
    "person": 0.48, "car": 1.85, "bus": 2.60, "truck": 2.50,
    "bicycle": 0.60, "motorcycle": 0.80, "dog": 0.35, "cat": 0.25,
    "chair": 0.50, "couch": 1.80, "potted plant": 0.35, "tv": 0.90,
    "laptop": 0.35, "dining table": 1.20, "cell phone": 0.08,
    "bottle": 0.08, "cup": 0.08, "suitcase": 0.45, "backpack": 0.35,
    "bench": 1.50, "bed": 1.60, "umbrella": 0.90,
}
REAL_WORLD_HEIGHTS = {
    "person": 1.70, "car": 1.50, "bus": 3.20, "truck": 3.00,
    "bicycle": 1.10, "motorcycle": 1.20, "dog": 0.55, "cat": 0.35,
    "chair": 0.90, "couch": 0.90, "potted plant": 0.45, "tv": 0.60,
    "laptop": 0.25, "dining table": 0.78, "bottle": 0.25,
    "cup": 0.12, "suitcase": 0.65, "backpack": 0.50,
    "bench": 0.85, "bed": 0.55, "umbrella": 1.80,
}
DEFAULT_REAL_WIDTH = 0.40
DEFAULT_REAL_HEIGHT = 0.80

_clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))


def adaptive_preprocess(frame: np.ndarray) -> np.ndarray:
    """CLAHE only when mean brightness < 85. Cost ~1-2 ms."""
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    if float(np.mean(gray)) < 85:
        lab = cv2.cvtColor(frame, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        l = _clahe.apply(l)
        return cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    return frame


def estimate_distance_multi(x1, y1, x2, y2, cname, frame_w, frame_h,
                            focal_length=DEFAULT_FOCAL_LENGTH):
    """Multi-metric pinhole distance (width + height + area blend). Returns metres."""
    box_w = max(1, x2 - x1)
    box_h = max(1, y2 - y1)
    frame_area = max(1, frame_w * frame_h)
    box_area = box_w * box_h

    real_w = REAL_WORLD_WIDTHS.get(cname, DEFAULT_REAL_WIDTH)
    real_h = REAL_WORLD_HEIGHTS.get(cname, DEFAULT_REAL_HEIGHT)

    d_width = (real_w * focal_length) / box_w
    d_height = (real_h * focal_length) / box_h
    area_ratio = (frame_area / box_area) ** 0.5
    d_area = (real_w + real_h) / 2.0 * area_ratio * 0.55

    box_aspect = box_w / box_h
    real_aspect = real_w / real_h

    if abs(box_aspect - real_aspect) < 0.5:
        d_est = 0.40 * d_width + 0.40 * d_height + 0.20 * d_area
    elif box_w >= box_h:
        d_est = 0.55 * d_width + 0.25 * d_height + 0.20 * d_area
    else:
        d_est = 0.25 * d_width + 0.55 * d_height + 0.20 * d_area

    return round(max(0.1, d_est), 2)


# =============================================================================
#  eSpeak NG TTS ENGINE (Requirement #14, #15)
# =============================================================================

class EspeakAudioEngine:
    """
    Asynchronous Non-Blocking TTS Engine.
    Requirement #14: detection loop never blocks on speech.
    Requirement #15: stale queued messages are drained; only newest kept.
    """

    def __init__(self, espeak_dir="D:\\project\\ultralytics-main\\espeak-ng-master"):
        self.espeak_dir = Path(espeak_dir)
        self.espeak_cmd = self._find_espeak_binary()
        self.speech_queue = queue.Queue()
        self.running = True
        self.is_speaking = False
        self.muted = False
        self.audio_cache_dir = Path("temp_audio")
        self.audio_cache_dir.mkdir(exist_ok=True)

        print("🔊 Audio Engine Initialized.")
        if self.espeak_cmd:
            print(f"  • Using eSpeak NG Engine: {self.espeak_cmd}")
        else:
            print("  • eSpeak NG binary not found. Using fallback Arabic TTS.")

        threading.Thread(target=self._worker, daemon=True).start()

    def _find_espeak_binary(self):
        possible_paths = [
            self.espeak_dir / "src" / "windows" / "espeak-ng.exe",
            self.espeak_dir / "espeak-ng.exe",
            Path("C:/Program Files/eSpeak NG/command_line/espeak-ng.exe"),
            Path("C:/Program Files (x86)/eSpeak NG/command_line/espeak-ng.exe"),
        ]
        for p in possible_paths:
            if p.exists():
                return str(p)
        try:
            res = subprocess.run(["where", "espeak-ng"], capture_output=True, text=True)
            if res.returncode == 0 and res.stdout.strip():
                return res.stdout.strip().splitlines()[0]
            res2 = subprocess.run(["where", "espeak"], capture_output=True, text=True)
            if res2.returncode == 0 and res2.stdout.strip():
                return res2.stdout.strip().splitlines()[0]
        except Exception:
            pass
        return None

    def queue_tts_message(self, arabic_text: str, priority: int = 1):
        """
        Requirement #15 — Queue a message, but first drain any stale
        messages that accumulated while TTS was busy.  Only the newest
        message survives.
        """
        if self.muted:
            return

        # Drain stale messages — the new one supersedes them
        drained = 0
        while not self.speech_queue.empty():
            try:
                self.speech_queue.get_nowait()
                self.speech_queue.task_done()
                drained += 1
            except queue.Empty:
                break

        self.speech_queue.put((priority, arabic_text))

    # Keep old name as alias for backward compatibility
    speak_arabic_warning = queue_tts_message

    def _worker(self):
        while self.running:
            try:
                priority, text = self.speech_queue.get(timeout=0.2)
            except queue.Empty:
                continue

            self.is_speaking = True
            try:
                if self.espeak_cmd:
                    cmd = [self.espeak_cmd, "-v", "ar", "-s", "145", text]
                    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                elif HAS_PYGAME:
                    audio_file = self.audio_cache_dir / f"tts_{hash(text)}.mp3"
                    if not audio_file.exists():
                        tts = gTTS(text=text, lang='ar', slow=False)
                        tts.save(str(audio_file))
                    pygame.mixer.music.load(str(audio_file))
                    pygame.mixer.music.play()
                    while pygame.mixer.music.get_busy() and self.running:
                        time.sleep(0.05)
                else:
                    print(f"🔊 [AUDIO]: {text}")
                    time.sleep(1.0)
            except Exception as e:
                print(f"Audio Error: {e}")
            finally:
                self.is_speaking = False
                self.speech_queue.task_done()

    def toggle_mute(self):
        self.muted = not self.muted
        print(f"🔊 {'MUTED' if self.muted else 'UNMUTED'}")
        return self.muted

    def stop(self):
        self.running = False


# =============================================================================
#  THREADED WEBCAM (preserved from v2.0)
# =============================================================================

class ThreadedWebcam:
    """Non-Blocking Threaded Webcam Stream"""

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


# =============================================================================
#  ASYNC YOLO INFERENCE ENGINE (preserved from v2.0)
# =============================================================================

class AsyncYOLOInference:
    """Async YOLO with ByteTrack + CLAHE."""

    def __init__(self, model_path="yolov8s.pt", imgsz=IMAGE_SIZE,
                 conf=CONF_THRESHOLD, iou=IOU_THRESHOLD, use_tracking=True):
        self.model_path = model_path
        self.imgsz = imgsz
        self.conf = conf
        self.iou = iou
        self.use_tracking = use_tracking

        print(f"  Loading model: {model_path} ...")
        self.model = YOLO(model_path)
        print(f"  Model loaded. Classes: {len(self.model.names)}")

        self.latest_frame = None
        self.latest_results = None
        self.running = True
        self.lock = threading.Lock()
        self.new_frame_event = threading.Event()
        self.inference_fps = 0.0
        self.preprocessed_count = 0

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

            proc_frame = adaptive_preprocess(frame)
            if proc_frame is not frame:
                self.preprocessed_count += 1

            try:
                if self.use_tracking:
                    results = self.model.track(
                        proc_frame, conf=self.conf, iou=self.iou,
                        imgsz=self.imgsz, tracker="bytetrack.yaml",
                        persist=True, verbose=False,
                    )
                else:
                    results = self.model.predict(
                        proc_frame, conf=self.conf, iou=self.iou,
                        imgsz=self.imgsz, verbose=False,
                    )
            except Exception as e:
                print(f"Inference error: {e}")
                continue

            now = time.time()
            dt = now - prev_time
            if dt > 0:
                self.inference_fps = 0.8 * self.inference_fps + 0.2 * (1.0 / dt)
            prev_time = now

            with self.lock:
                self.latest_results = results[0]

    def get_results(self):
        with self.lock:
            return self.latest_results, self.inference_fps

    def set_imgsz(self, v):
        self.imgsz = v
        print(f"⚡ Inference Size: {v}px")

    def set_conf(self, v):
        self.conf = v
        print(f"🎯 Conf: {v:.2f}")

    def reload_model(self, model_path):
        print(f"🔄 Reloading: {model_path} ...")
        self.model_path = model_path
        self.model = YOLO(model_path)
        print(f"✅ Loaded: {model_path}")

    def stop(self):
        self.running = False


# =============================================================================
#  APPROACH DETECTOR (preserved from v2.0)
# =============================================================================

class ApproachDetector:
    """Flags objects whose bbox area is growing ≥ threshold across frames."""

    def __init__(self, growth_threshold=0.15, min_frames=2):
        self.prev_areas: dict[int, list[float]] = defaultdict(list)
        self.growth_threshold = growth_threshold
        self.min_frames = min_frames

    def update(self, track_id: int, box_area: float) -> bool:
        history = self.prev_areas[track_id]
        history.append(box_area)
        if len(history) > 5:
            history.pop(0)
        if len(history) < self.min_frames + 1:
            return False
        oldest = history[0]
        if oldest <= 0:
            return False
        return (history[-1] - oldest) / oldest >= self.growth_threshold

    def cleanup(self, active_ids: set):
        dead = [tid for tid in self.prev_areas if tid not in active_ids]
        for tid in dead:
            del self.prev_areas[tid]


# =============================================================================
#  GET CENTER OBJECTS — single-frame pipeline step (Requirement #23)
# =============================================================================

def get_center_objects(res, names, frame_w, frame_h, focal_length,
                       danger_distance, use_tracking, approach_detector):
    """
    Process one YOLO result frame.  Returns two lists:
      all_detections   — every important detection with metadata (for drawing)
      center_objects   — only center+close objects (for announcement)
    """
    all_detections = []
    center_objects = []
    active_track_ids = set()

    boxes = res.boxes
    if boxes is None or len(boxes) == 0:
        return all_detections, center_objects, active_track_ids

    cls_ids = boxes.cls.cpu().numpy().astype(int)
    confs = boxes.conf.cpu().numpy()
    xyxy = boxes.xyxy.cpu().numpy().astype(int)

    track_ids = None
    if use_tracking and boxes.id is not None:
        track_ids = boxes.id.cpu().numpy().astype(int)

    for idx, (box, cid, cnf) in enumerate(zip(xyxy, cls_ids, confs)):
        cname = names[cid].lower()
        if cname not in IMPORTANT_CLASSES:
            continue

        x1, y1, x2, y2 = box
        box_area = max(1, (x2 - x1) * (y2 - y1))
        track_id = int(track_ids[idx]) if track_ids is not None else -1
        if track_id >= 0:
            active_track_ids.add(track_id)

        dist_m = estimate_distance_multi(x1, y1, x2, y2, cname,
                                         frame_w, frame_h, focal_length)
        position = get_position_label(x1, x2, frame_w)
        is_close = dist_m <= danger_distance

        is_approaching = False
        if track_id >= 0:
            is_approaching = approach_detector.update(track_id, box_area)

        # Danger = close AND (center OR approaching)
        is_danger = is_close and (position == "CENTER" or is_approaching)

        det = {
            "cname": cname, "distance": dist_m, "conf": float(cnf),
            "box": box, "box_area": box_area, "track_id": track_id,
            "is_approaching": is_approaching, "position": position,
            "is_close": is_close, "is_danger": is_danger,
        }
        all_detections.append(det)

        if is_danger:
            center_objects.append(det)

    return all_detections, center_objects, active_track_ids


# =============================================================================
#  CLI ARGUMENTS
# =============================================================================

def parse_args():
    p = argparse.ArgumentParser(
        description="Real-Time Assistive Vision v3.0 — Multi-Object Grouped Announcements"
    )
    p.add_argument("--model", default="yolov8s.pt", help="YOLO model path")
    p.add_argument("--source", default="0", help="Camera index or video file")
    p.add_argument("--conf", type=float, default=CONF_THRESHOLD)
    p.add_argument("--iou", type=float, default=IOU_THRESHOLD)
    p.add_argument("--imgsz", type=int, default=IMAGE_SIZE)
    p.add_argument("--danger_dist", type=float, default=DEFAULT_DANGER_DISTANCE)
    p.add_argument("--cooldown", type=float, default=TTS_COOLDOWN)
    p.add_argument("--no_tracking", action="store_true")
    p.add_argument("--focal", type=float, default=DEFAULT_FOCAL_LENGTH)
    return p.parse_args()


# =============================================================================
#  MAIN APPLICATION
# =============================================================================

def main():
    args = parse_args()
    source = int(args.source) if args.source.isdigit() else args.source
    use_tracking = not args.no_tracking

    print("\n==========================================================================")
    print(" 👁️  Assistive Vision v3.0 — Multi-Object Grouped Arabic Announcements")
    print(f" Model        : {args.model}")
    print(f" imgsz        : {args.imgsz}px")
    print(f" conf / iou   : {args.conf} / {args.iou}")
    print(f" Danger Dist  : {args.danger_dist}m")
    print(f" TTS Cooldown : {args.cooldown}s")
    print(f" Center Zone  : {CENTER_ZONE_WIDTH*100:.0f}% width, "
          f"{CENTER_OVERLAP_THRESHOLD*100:.0f}% overlap threshold")
    print(f" Tracking     : {'ByteTrack' if use_tracking else 'Disabled'}")
    print(f" Pluralization: {'ON' if ENABLE_ARABIC_PLURALIZATION else 'OFF'}")
    print(f" Grouping     : {'ON' if ENABLE_MULTI_OBJECT_ANNOUNCEMENT else 'OFF'}")
    print("==========================================================================")
    print("\nControls:")
    print(" [m] Mute/Unmute   [1-4] Resolution   [n]/[s] Model   [q] Quit")
    print(" [+]/[-] Danger distance   [S] Snapshot")
    print("==========================================================================\n")

    audio_engine = EspeakAudioEngine()
    webcam = ThreadedWebcam(source=source).start()
    time.sleep(0.5)

    ret, frame = webcam.read()
    if not ret or frame is None:
        print(f"Error: Could not access camera source {source}")
        webcam.stop()
        audio_engine.stop()
        sys.exit(1)

    print("Loading YOLO Engine...")
    engine = AsyncYOLOInference(
        model_path=args.model, imgsz=args.imgsz,
        conf=args.conf, iou=args.iou, use_tracking=use_tracking,
    ).start()

    approach_detector = ApproachDetector(growth_threshold=0.15, min_frames=2)
    snapshot_dir = Path("snapshots")
    snapshot_dir.mkdir(exist_ok=True)

    window_name = "Assistive Vision v3.0"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1280, 720)

    # ── Announcement state (Requirements #10, #11) ───────────────────────────
    last_announced_sig: tuple = ()
    last_announcement_time: float = 0.0

    danger_distance_m = args.danger_dist
    focal_length = args.focal
    cooldown_sec = args.cooldown
    current_model_name = args.model

    render_prev_time = time.time()
    render_fps = 0.0
    active_warning_text = ""
    active_warning_display_until = 0.0

    while True:
        ret, frame = webcam.read()
        if not ret or frame is None:
            break

        frame_h, frame_w = frame.shape[:2]

        # Render FPS
        now = time.time()
        dt = now - render_prev_time
        if dt > 0:
            render_fps = 0.9 * render_fps + 0.1 * (1.0 / dt)
        render_prev_time = now

        engine.submit_frame(frame)
        res, inf_fps = engine.get_results()

        annotated_frame = frame.copy()

        # ── Draw center zone ──────────────────────────────────────────────────
        zone_left = int(frame_w * (0.5 - CENTER_ZONE_WIDTH / 2.0))
        zone_right = int(frame_w * (0.5 + CENTER_ZONE_WIDTH / 2.0))

        overlay_corridor = annotated_frame.copy()
        cv2.rectangle(overlay_corridor, (zone_left, 60),
                      (zone_right, frame_h), (0, 0, 80), -1)
        cv2.addWeighted(overlay_corridor, 0.20, annotated_frame, 0.80, 0,
                        annotated_frame)

        cv2.line(annotated_frame, (zone_left, 60), (zone_left, frame_h),
                 (0, 180, 255), 2, cv2.LINE_AA)
        cv2.line(annotated_frame, (zone_right, 60), (zone_right, frame_h),
                 (0, 180, 255), 2, cv2.LINE_AA)

        cv2.putText(annotated_frame, "LEFT", (30, 95),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1, cv2.LINE_AA)
        cv2.putText(annotated_frame, "CENTER DANGER ZONE",
                    (zone_left + 15, 95),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 240, 255), 2, cv2.LINE_AA)
        cv2.putText(annotated_frame, "RIGHT", (zone_right + 20, 95),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1, cv2.LINE_AA)

        # ── Process detections ────────────────────────────────────────────────
        all_dets = []
        center_objects = []
        active_track_ids = set()

        if res is not None:
            all_dets, center_objects, active_track_ids = get_center_objects(
                res, res.names, frame_w, frame_h, focal_length,
                danger_distance_m, use_tracking, approach_detector,
            )

        approach_detector.cleanup(active_track_ids)

        # ── Draw all detections (visual only) ─────────────────────────────────
        for det in all_dets:
            x1, y1, x2, y2 = det["box"]
            cname = det["cname"]
            dist_m = det["distance"]
            position = det["position"]
            is_danger = det["is_danger"]
            is_approaching = det["is_approaching"]
            track_id = det["track_id"]

            if is_danger:
                box_color, tag_bg = (0, 0, 255), (0, 0, 200)
            elif position == "CENTER":
                box_color, tag_bg = (0, 240, 255), (0, 180, 220)
            else:
                box_color, tag_bg = (0, 255, 120), (0, 160, 80)

            cv2.rectangle(annotated_frame, (x1, y1), (x2, y2),
                          box_color, 3 if is_danger else 2, cv2.LINE_AA)

            ar_name = ARABIC_OBJECT_NAMES.get(cname, cname)
            tid_tag = f" [#{track_id}]" if track_id >= 0 else ""
            appr = " ⬆APR" if is_approaching else ""
            label = f"{cname}{tid_tag} ({ar_name}) | {dist_m:.2f}m | {position}{appr}"
            if is_danger:
                label = f"⚠ {label}"

            (lw, lh), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.45, 1)
            cv2.rectangle(annotated_frame, (x1, y1 - 22), (x1 + lw + 10, y1),
                          tag_bg, -1)
            cv2.putText(annotated_frame, label, (x1 + 5, y1 - 6),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.45,
                        (255, 255, 255) if is_danger else (0, 0, 0),
                        1, cv2.LINE_AA)

        # ── GROUPED ANNOUNCEMENT (Requirements #2, #6, #9, #10) ──────────────
        now = time.time()

        if center_objects and ENABLE_MULTI_OBJECT_ANNOUNCEMENT:
            # Collect class names for all center+close objects
            # Use track IDs to deduplicate if available (Requirement #13)
            seen_track_ids = set()
            deduplicated_names = []
            for obj in center_objects:
                tid = obj["track_id"]
                if tid >= 0:
                    if tid in seen_track_ids:
                        continue  # same physical object detected twice
                    seen_track_ids.add(tid)
                deduplicated_names.append(obj["cname"])

            if deduplicated_names:
                current_sig = make_group_signature(deduplicated_names)

                if should_announce(current_sig, last_announced_sig,
                                   last_announcement_time, now, cooldown_sec):
                    # Generate ONE Arabic sentence
                    arabic_msg = generate_arabic_multi_object_message(deduplicated_names)

                    # Send ONE TTS request (Requirement #9)
                    audio_engine.queue_tts_message(arabic_msg, priority=1)

                    last_announced_sig = current_sig
                    last_announcement_time = now

                    # Build English log summary
                    counts = group_objects_by_class(deduplicated_names)
                    summary_parts = [f"{c}×{n}" for c, n in
                                     sort_objects_by_priority(counts)]
                    closest = min(center_objects, key=lambda o: o["distance"])

                    active_warning_text = f"🔊 {arabic_msg}"
                    active_warning_display_until = now + 3.0
                    print(f"🔊 GROUPED ANNOUNCEMENT: {arabic_msg}  "
                          f"[{', '.join(summary_parts)}]  "
                          f"closest={closest['cname']}@{closest['distance']:.2f}m")

        elif center_objects and not ENABLE_MULTI_OBJECT_ANNOUNCEMENT:
            # Fallback: single-object mode (v2 behavior)
            center_objects.sort(key=lambda o: (o["distance"],
                                               -int(o["is_approaching"])))
            target = center_objects[0]
            t_cname = target["cname"]
            ar_name = ARABIC_OBJECT_NAMES.get(t_cname, t_cname)
            msg = f"{ar_name} أمامك"
            if (now - last_announcement_time) >= cooldown_sec:
                audio_engine.queue_tts_message(msg, priority=1)
                last_announcement_time = now
                active_warning_text = f"🔊 {msg}"
                active_warning_display_until = now + 2.5
                print(f"🔊 SINGLE: {msg} ({t_cname}@{target['distance']:.2f}m)")

        # ── HUD ───────────────────────────────────────────────────────────────
        overlay_hud = annotated_frame.copy()
        cv2.rectangle(overlay_hud, (0, 0), (frame_w, 58), (10, 12, 18), -1)
        cv2.addWeighted(overlay_hud, 0.85, annotated_frame, 0.15, 0,
                        annotated_frame)

        status = ("MUTED" if audio_engine.muted
                  else ("SPEAKING" if audio_engine.is_speaking else "READY"))
        mdl = Path(current_model_name).stem.upper()
        hud = (f"FPS:{render_fps:.1f} | INF:{inf_fps:.1f} | "
               f"imgsz:{engine.imgsz} | {mdl} | "
               f"DANGER:{danger_distance_m:.1f}m | AUDIO:{status}")
        cv2.putText(annotated_frame, hud, (12, 38),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, (0, 255, 200), 2, cv2.LINE_AA)

        # ── Warning banner ────────────────────────────────────────────────────
        if time.time() < active_warning_display_until:
            cv2.rectangle(annotated_frame,
                          (20, frame_h - 68), (frame_w - 20, frame_h - 16),
                          (0, 0, 180), -1)
            cv2.rectangle(annotated_frame,
                          (20, frame_h - 68), (frame_w - 20, frame_h - 16),
                          (0, 240, 255), 2)
            cv2.putText(annotated_frame,
                        f"ALERT: {active_warning_text}",
                        (36, frame_h - 34),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.62,
                        (255, 255, 255), 2, cv2.LINE_AA)

        cv2.imshow(window_name, annotated_frame)

        # ── Hotkeys ───────────────────────────────────────────────────────────
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('m'):
            audio_engine.toggle_mute()
        elif key == ord('1'):
            engine.set_imgsz(320)
        elif key == ord('2'):
            engine.set_imgsz(480)
        elif key == ord('3'):
            engine.set_imgsz(640)
        elif key == ord('4'):
            engine.set_imgsz(768)
        elif key == ord('n'):
            engine.reload_model("yolov8n.pt")
            current_model_name = "yolov8n.pt"
        elif key == ord('s'):
            engine.reload_model("yolov8s.pt")
            current_model_name = "yolov8s.pt"
        elif key == ord('+') or key == ord('='):
            danger_distance_m = min(4.0, danger_distance_m + 0.2)
            print(f"🎯 Danger Distance: {danger_distance_m:.1f}m")
        elif key == ord('-') or key == ord('_'):
            danger_distance_m = max(0.6, danger_distance_m - 0.2)
            print(f"🎯 Danger Distance: {danger_distance_m:.1f}m")
        elif key == ord('S'):
            snap_path = snapshot_dir / f"assistive_v3_{int(time.time())}.jpg"
            cv2.imwrite(str(snap_path), annotated_frame)
            print(f"📸 Snapshot: {snap_path}")

    engine.stop()
    webcam.stop()
    audio_engine.stop()
    cv2.destroyAllWindows()
    print(f"\n📊 CLAHE frames: {engine.preprocessed_count}")
    print("Assistive Vision v3.0 stopped.")


if __name__ == "__main__":
    main()
