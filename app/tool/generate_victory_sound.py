"""Generate the original offline victory chime. No third-party samples."""
import math
from pathlib import Path
import struct
import wave

RATE = 44100
DURATION = 1.65
# An ascending major arpeggio resolves into a soft final chord.
NOTES = [(0, 523.25, .38), (.17, 659.25, .38), (.34, 783.99, .4),
         (.53, 1046.5, .95), (.53, 659.25, .95), (.53, 783.99, .95)]
samples = []
for index in range(round(RATE * DURATION)):
    time = index / RATE
    value = 0.0
    for start, frequency, duration in NOTES:
        local = time - start
        if 0 <= local < duration:
            envelope = min(1, local / .012) * (1 - local / duration) ** 2
            value += .17 * envelope * (math.sin(2 * math.pi * frequency * local)
                                       + .2 * math.sin(4 * math.pi * frequency * local))
    samples.append(round(max(-.95, min(.95, value)) * 32767))
target = Path(__file__).resolve().parents[1] / 'assets/audio/victory.wav'
target.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(target), 'wb') as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(RATE)
    output.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
print(f'Wrote {target.name}: {DURATION}s, mono PCM, {target.stat().st_size} bytes')
