# Reverse Warp Delay

A [Faust](https://faust.grame.fr/) LV2/JACK DSP effect combining a classic reverse delay with two generative twists: **envelope-driven pitch glide** and **decaying feedback darkness**.

---

## The Concept

Standard reverse delays play back a buffer in reverse — predictable, musical, useful. This one goes further:

**Twist 1 — Envelope → Pitch**  
The reverse read-head position is offset in real time by the input signal's amplitude envelope. Loud transients push the pointer earlier in the buffer, which is physically equivalent to accelerating a tape — the reversed echo pitch-glides upward on hits and settles back during quiet passages. No explicit pitch-shifting algorithm; it falls out of the geometry.

**Twist 2 — Decaying Darkness**  
The feedback path passes through a 2nd-order low-pass filter whose cutoff is controlled by the `Darkness` knob (300 Hz → 20 kHz). Each round-trip bleeds high-frequency energy, so the tail degrades from crisp to warm smear over time — like the delay is burning through tape heads.

---

## Parameters

| Parameter | Range | Description |
|---|---|---|
| Delay Time | 50–1500 ms | Length of each reversed chunk |
| Feedback | 0.0–0.92 | Repeat intensity |
| Dry/Wet | 0.0–1.0 | Blend between dry and processed signal |
| Warp Rate | 0.01–3.0 Hz | LFO speed modulating the read head |
| Warp Depth | 0.0–0.45 | LFO amplitude (as fraction of buffer) |
| Env → Pitch | 0.0–1.0 | How much input loudness shifts the reverse pitch |
| Darkness | 0.0–1.0 | Feedback low-pass aggressiveness |

---

## Signal Architecture

```
(input + fb·prev) ──► rwtable
                         ├── wIdx  =  ba.time % delN          (write: forward)
                         └── rIdx  =  (delN-1-phase)          (read: reversed)
                                      + warpLFO               (sinusoidal wobble)
                                      + envMod                (amplitude-driven glide)
                                      : max(0) : min(delN-1)  (clamped)
         ──► lowpass(2, fbCutoff) ──► output (& feedback loop)
```

---

## Build

**LV2 plugin:**
```bash
faust2lv2 reverse_warp_delay.dsp
```

**JACK standalone:**
```bash
faust2jack reverse_warp_delay.dsp
```

**Web (via [Faust Playground](https://faustide.grame.fr/)):**  
Paste `reverse_warp_delay.dsp` directly — no build step needed.

Tested with Faust 2.x and g++. Requires a C++11-capable compiler.

---

## Usage Tips

- `Env → Pitch` at 0.2–0.3 gives subtle, natural glide. Push past 0.7 for wild pitch throws on hard transients.
- `Darkness` at 0.6–0.8 + `Feedback` at 0.6+ creates a long, degrading shimmer tail ideal for pads and ambient work.
- Short delay times (50–150 ms) at high warp depth produce granular, stuttery textures.
- At `Feedback` = 0 the effect functions as a one-shot reverse with pitch glide — clean and controlled.

---

## License

MIT License

Copyright (c) 2026 Claude (Anthropic)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
