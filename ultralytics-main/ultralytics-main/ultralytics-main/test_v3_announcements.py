"""
Test Suite for v3.0 Assistive Vision — Arabic Multi-Object Announcements
Tests the 10 required cases from the specification.
"""
import sys, os

# Allow importing from the same directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from assistive_yolov8_espeak import (
    generate_arabic_multi_object_message,
    generate_arabic_object_phrase,
    group_objects_by_class,
    sort_objects_by_priority,
    make_group_signature,
    should_announce,
    is_in_center_zone,
    compute_center_overlap,
    EspeakAudioEngine,
)

PASS = 0
FAIL = 0


def test(name, got, expected):
    global PASS, FAIL
    ok = got == expected
    status = "PASS" if ok else "FAIL"
    if ok:
        PASS += 1
    else:
        FAIL += 1
    print(f"  [{status}] {name}")
    if not ok:
        print(f"         Expected: {expected}")
        print(f"         Got:      {got}")
    return ok


print("=" * 72)
print("  TEST SUITE — v3.0 Multi-Object Arabic Announcements")
print("=" * 72)

# ─── Test 1: Single person ────────────────────────────────────────────────────
print("\nTest 1: Single person")
test("1 person", generate_arabic_multi_object_message(["person"]),
     "شخص أمامك")

# ─── Test 2: Two persons ─────────────────────────────────────────────────────
print("\nTest 2: Two persons (dual form)")
test("2 persons", generate_arabic_multi_object_message(["person", "person"]),
     "يوجد شخصان أمامك")

# ─── Test 3: Three persons ───────────────────────────────────────────────────
print("\nTest 3: Three persons (plural + number)")
test("3 persons", generate_arabic_multi_object_message(["person", "person", "person"]),
     "يوجد 3 أشخاص أمامك")

# ─── Test 4: 1 person + 1 car ────────────────────────────────────────────────
print("\nTest 4: person + car (two classes)")
test("person+car", generate_arabic_multi_object_message(["person", "car"]),
     "يوجد شخص وسيارة أمامك")

# ─── Test 5: 2 persons + 1 car ───────────────────────────────────────────────
print("\nTest 5: 2 persons + 1 car")
test("2person+1car", generate_arabic_multi_object_message(["person", "person", "car"]),
     "يوجد شخصان وسيارة أمامك")

# ─── Test 6: 2 persons + 2 cars + 1 chair ────────────────────────────────────
print("\nTest 6: 2 persons + 2 cars + 1 chair")
test("2p+2c+1ch", generate_arabic_multi_object_message(
     ["person", "person", "car", "car", "chair"]),
     "يوجد شخصان وسيارتان وكرسي أمامك")

# ─── Test 7: Center zone overlap ─────────────────────────────────────────────
print("\nTest 7: Center zone overlap detection")
# Frame 1000px wide, center zone 30%–70% = 300–700
# Object fully inside center: x1=350, x2=650 → overlap = 100%
test("fully inside", is_in_center_zone(350, 650, 1000), True)
# Object fully outside (left): x1=0, x2=100 → overlap = 0%
test("fully outside left", is_in_center_zone(0, 100, 1000), False)
# Object fully outside (right): x1=900, x2=1000 → overlap = 0%
test("fully outside right", is_in_center_zone(900, 1000, 1000), False)
# Object partially in: x1=200, x2=400 → overlap portion = (400-300)/200 = 50%
test("partial overlap (50%)", is_in_center_zone(200, 400, 1000), True)
# Object barely in: x1=250, x2=320 → overlap = (320-300)/70 = 28.6% (> 20%)
test("barely above threshold", is_in_center_zone(250, 320, 1000), True)
# Object just below threshold: x1=260, x2=310 → overlap = (310-300)/50 = 20% (boundary)
overlap_val = compute_center_overlap(260, 310, 1000)
test(f"at threshold ({overlap_val:.2%})", overlap_val >= 0.20, True)

# ─── Test 8: Temporal grouping (same objects → no repeat) ────────────────────
print("\nTest 8: Temporal grouping — same objects suppress repeat")
sig1 = make_group_signature(["person", "car"])
sig2 = make_group_signature(["person", "car"])
test("same sig", sig1, sig2)
# Same group, 1 second later, cooldown=3 → should NOT announce
test("suppress repeat", should_announce(sig2, sig1, 100.0, 101.0, 3.0), False)
# Same group, 4 seconds later, cooldown=3 → SHOULD re-announce
test("re-announce after cooldown", should_announce(sig2, sig1, 100.0, 104.0, 3.0), True)

# ─── Test 9: New object enters → new announcement ───────────────────────────
print("\nTest 9: New object enters center → new announcement")
sig_old = make_group_signature(["person", "car"])
sig_new = make_group_signature(["person", "person", "car"])
test("different sig", sig_old != sig_new, True)
# Different group → announce even if only 0.5s passed (> 0.3s debounce)
test("announce changed group", should_announce(sig_new, sig_old, 100.0, 100.5, 3.0), True)

# ─── Test 10: TTS queue draining (non-blocking) ─────────────────────────────
print("\nTest 10: TTS non-blocking + queue draining")
engine = EspeakAudioEngine.__new__(EspeakAudioEngine)
engine.speech_queue = __import__("queue").Queue()
engine.muted = False
engine.running = False  # don't start worker

# Queue 5 messages
for i in range(5):
    engine.speech_queue.put((1, f"msg{i}"))

test("queue had 5 msgs", engine.speech_queue.qsize(), 5)

# Now call queue_tts_message — should drain old + add new
engine.queue_tts_message("final message")
test("queue drained to 1", engine.speech_queue.qsize(), 1)

_, final = engine.speech_queue.get_nowait()
test("newest message kept", final, "final message")

# ─── Additional tests: pluralization edge cases ──────────────────────────────
print("\n--- Additional: Pluralization edge cases ---")

test("single car", generate_arabic_object_phrase("car", 1), "سيارة")
test("dual car", generate_arabic_object_phrase("car", 2), "سيارتان")
test("3 cars", generate_arabic_object_phrase("car", 3), "3 سيارات")
test("single chair", generate_arabic_object_phrase("chair", 1), "كرسي")
test("dual chair", generate_arabic_object_phrase("chair", 2), "كرسيان")
test("3 chairs", generate_arabic_object_phrase("chair", 3), "3 كراسي")

# Unsupported class fallback
test("unknown class singular",
     generate_arabic_object_phrase("toothbrush", 1), "فرشاة أسنان")
test("unknown class plural",
     generate_arabic_object_phrase("toothbrush", 3), "3 من نوع فرشاة أسنان")

# ─── Additional: Priority ordering ───────────────────────────────────────────
print("\n--- Additional: Priority ordering ---")

# chair, person, car, person → person should come first
msg = generate_arabic_multi_object_message(["chair", "person", "car", "person"])
test("priority ordering",
     msg, "يوجد شخصان وسيارة وكرسي أمامك")

# Single class multiple
msg2 = generate_arabic_multi_object_message(["car", "car", "car"])
test("3 cars only", msg2, "يوجد 3 سيارات أمامك")

# Empty
test("empty list", generate_arabic_multi_object_message([]), "")


# ─── Summary ─────────────────────────────────────────────────────────────────
print("\n" + "=" * 72)
print(f"  RESULTS: {PASS} passed, {FAIL} failed, {PASS+FAIL} total")
if FAIL == 0:
    print("  ALL TESTS PASSED")
else:
    print(f"  {FAIL} TEST(S) FAILED")
print("=" * 72)

sys.exit(0 if FAIL == 0 else 1)
