# Grok's Lorenzian Vortex Entangler

A chaotic, infinitely-evolving stereo audio effect written in **Faust**.

Real-time 3D Lorenz attractor modulating:

- asymmetric cross-feedback delay network with distortion & filtering
- Zita-style FDN reverb (late reflections + damping modulated)
- 16-voice resonant filter bank (spread and Q modulated by chaos)

Every run is unique — deterministic chaos means no two performances are ever exactly the same.

## Features

- Audio-rate Lorenz system (σ=10, ρ=28, β=8/3) with clean initialization
- Stereo delay with chaos-controlled times, feedback, cross-mix & tanh pre-distortion
- Zita Rev1 stereo reverb with modulated pre-delay, crossover, decay & high-freq damping
- 16 parallel bandpass resonators whose center frequencies and Q are twisted by the attractor
- Soft-clip output stage + dry/wet + master gain
- Never blows up (thanks to careful saturation & min(0.995) feedback clamping)

## Screenshots / Demo

*(Add a screenshot here when you have one — or a short video/gif of it running on a pad or guitar would be perfect)*

## Requirements

- Faust ≥ 2.5 (tested with recent versions)
- LV2 host (Ardour, Carla, Reaper+LV2, etc.)
- or use faust2vst, faust2supercollider, faust2caqt, etc.

## Build (LV2)

```bash
faust2lv2 grok.dsp
# → creates grok.lv2/ folder
```

Copy the resulting `grok.lv2` folder to your LV2 path:

- `~/.lv2/` (user)
- `/usr/lib/lv2/` or `/usr/local/lib/lv2/` (system)

## Controls

| Control              | Range       | Typical sweet spot | What it does                              |
|----------------------|-------------|--------------------|-------------------------------------------|
| Dry/Wet              | 0–100 %     | 40–80              | Blend dry ↔ fully wet chaos               |
| Pre-Distortion       | 1–5         | 1.5–3              | Input drive into tanh saturation          |
| Master Gain          | -12 – +12 dB| 0 – +6             | Final output level                        |
| Chaos Speed (dt)     | 0.0005–0.02 | 0.003–0.008        | How fast the attractor evolves            |
| Chaos Amount         | 0–1         | 0.6–0.9            | Depth of modulation (0 = static)          |
| Base Delay (ms)      | 10–1200 ms  | 150–400            | Center delay time                         |
| Feedback             | 0–0.98      | 0.65–0.88          | Delay regeneration (higher = more intense)|
| Cross-Mix            | 0–1         | 0.35–0.65          | L→R and R→L feedback blending             |
| Reverb Predelay (ms) | 0–80 ms     | 10–30              | Early reflection delay                    |
| Reverb Decay (s)     | 0.5–12 s    | 2.5–5              | Reverb tail length                        |
| Resonance Spread     | 0–2         | 0.7–1.5            | How much the filter bank is warped        |
| Resonance Q          | 1–12        | 4–9                | Sharpness of the resonator peaks          |

## License

MIT License

Copyright (c) 2025 Grok (xAI)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Author

Grok (built by xAI)  
(with stubborn debugging help from DeMoD @DeMoDLLC)

Enjoy the butterfly effect.  
May your mixes never repeat. 🌀
