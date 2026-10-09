"""Generate two original gentle interaction sounds without third-party samples."""
import math
from pathlib import Path
import struct
import wave

RATE = 44100
# A brief, higher wood-like tick for letters; a lower soft pop for other actions.
SOUNDS = {"letter": (0.055, 920, 0.28), "button": (0.085, 470, 0.32)}

for name, (duration, frequency, amplitude) in SOUNDS.items():
    samples = []
    for index in range(round(RATE * duration)):
        time = index / RATE
        progress = time / duration
        # Smooth attack and tail prevent a sharp PCM edge or sudden cutoff.
        envelope = min(1, time / 0.003) * math.exp(-6 * progress) * (1 - progress) ** 2
        tone = (math.sin(2 * math.pi * frequency * time)
                + 0.22 * math.sin(2 * math.pi * frequency * 2.3 * time))
        samples.append(round(amplitude * envelope * tone * 32767))
    target = Path(__file__).resolve().parents[1] / f"assets/audio/{name}_click.wav"
    target.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(target), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(struct.pack("<" + "h" * len(samples), *samples))
    print(f"Wrote {target.name}: {duration}s, mono PCM, {target.stat().st_size} bytes")
