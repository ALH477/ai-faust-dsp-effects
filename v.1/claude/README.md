# Strange Attractor Reverb

A 4-channel Feedback Delay Network reverb driven by a Lorenz chaotic attractor, implemented in [Faust DSP](https://faust.grame.fr/).

**Author:** Claude (Anthropic)  
**License:** MIT  
**Version:** 2.0  

---

## What It Is

Conventional reverb modulation uses LFOs — periodic oscillators that repeat every N samples, which introduces subtle but measurable pitch periodicity into the tail. This plugin replaces the LFO entirely with the **Lorenz strange attractor**: a three-variable chaotic differential system that is *aperiodic* (never repeats) yet *bounded* (stays within a finite region of state-space). The result is delay modulation that is temporally organic with no flutter period to detect.

The attractor runs at full audio rate. Its X, Y, Z outputs — plus the X·Z cross-product (itself a genuine Lorenz dynamical term, appearing in dz/dt) — drive four independent delay line modulators inside a Hadamard-mixed FDN.

---

## Architecture

```
L ──┐
    ├── Σ ──► [15 ms Predelay] ──────────────────────────────┐
R ──┘                                                        ↓
                                                       [FDN-4 Core]
Lorenz(dt=0.006) ──► (lx, ly, lz) ──► (d1, d2, d3, d4)     │
σ=10, ρ=28, β=8/3                                            │
                                              ┌──────────────┴──────────────┐
                                              │  [Hadamard 4×4]             │
                                              │  [Allpass fractional delay] │ ← Lorenz-warped
                                              │  [Soft saturation x/(1+|x|)]│
                                              │  [1-pole lowpass]           │
                                              │  [Staggered gain × RT60]    │
                                              └──────────────┬──────────────┘
                                                             │
                                                   [Stereo Decorrelation]
                                                      (y0+y2, y1+y3)
                                                             │
                                                      [Wet/Dry Mix] ──► L/R
```

### Design Decisions

**Lorenz vs. LFO.** An LFO repeats every N samples, producing a periodic pitch artifact in the reverb tail. The Lorenz attractor is provably aperiodic — its trajectory never closes — yet remains bounded within its strange attractor. Modulation depth is consistent; spectral colouration from periodicity is absent.

**Allpass interpolation.** Linear interpolation (sinc roll-off above ~0.4·Nyquist) introduces amplitude aliases at high modulation depths that read as distortion. First-order allpass interpolation has unit magnitude at all frequencies. The phase artifact it introduces functions as additional diffusion — appropriate in a reverb feedback path.

**Hadamard mixing.** The 4×4 Hadamard matrix has all entries ±0.5 and is orthogonal (all singular values = 1). Every output sees energy from every input on every cycle. Mixing occurs at the write head — the FDN stores already-mixed signal — so the first-echo artifact common to post-delay FDN topologies does not appear.

**Cross-term modulator.** The X·Z product appears directly in the Lorenz dz/dt equation. It is a true dynamical term with a spectral character distinct from X or Z alone — higher bandwidth, differently distributed energy. Applied to d4, this gives four genuinely independent modulators from a single 3-variable system.

**Soft saturation in feedback.** `y = x/(1+|x|)` is bijective on ℝ→(−1,1), unit-gain at the origin, and smooth everywhere. In the feedback path it acts as a soft-knee per-mode compressor: preventing any single resonant frequency from running away while preserving transient character.

**Staggered RT60.** Gain offsets `{1, 0.9993, 0.9987, 0.9981}` give each channel a different decay slope. Complex material decays at different rates per channel, producing a natural multi-slope tail rather than a single exponential.

---

## Parameters

| # | Name | Range | Default | Description |
|---|------|--------|---------|-------------|
| 0 | Size | 0.05 – 2.0 | 0.6 | Room scale. Multiplies all base delay times. |
| 1 | Decay | 0.0 – 0.9999 | 0.84 | Feedback gain. Controls RT60. |
| 2 | Chaos | 0.0 – 1.0 | 0.5 | Lorenz modulation depth (±2 ms max). |
| 3 | Damp | 100 – 20000 Hz | 5000 | 1-pole lowpass cutoff in feedback path. |
| 4 | Mix | 0.0 – 1.0 | 0.35 | Wet/dry ratio. |

### Parameter Guide

**Size**
- `0.1 – 0.4` — tight rooms, chamber, plate simulation
- `0.5 – 0.8` — medium halls
- `0.9 – 2.0` — cathedrals, infinite spaces

**Decay**
- `0.5 – 0.7` — short reverb, percussion
- `0.8 – 0.92` — natural room character
- `0.93+` — long, evolving tails for pads and drones
- `> 0.9999` — self-oscillation. `softclip` bounds amplitude; the network rings on the natural modes of the prime delay lines. Karplus-Strong-like resonator character.

**Chaos**
- `0.0` — static delays, conventional FDN reverb
- `0.2 – 0.4` — subtle organic flutter
- `0.6 – 0.8` — pronounced pitch spread, diffuse shimmer
- `1.0` — maximum aperiodic warping. At high Decay: evolving drone resonances.

**Damp**
- `100 Hz` — very dark, heavy absorption (stone)
- `5000 Hz` — balanced (wood, glass)
- `20000 Hz` — bright, minimal absorption (tile, concrete)

---

## Creative Uses

**Self-oscillation drone**  
`Mix=1.0, Decay=0.998, Chaos=0.8`  
Feeds back into itself. The Lorenz attractor prevents modal locking; the result is an evolving, non-repeating resonant drone.

**Infinite freeze**  
`Decay→0.9999, Mix=1.0, Size=1.0`  
Near-infinite sustain with chaotic internal motion. The tail never settles.

**Pitch smear**  
`Chaos=1.0, Size=1.2`  
Washes fast transients into dense chromatic clouds. Useful on drums sent to a parallel bus.

---

## Lorenz System Reference

```
dx/dt = σ(y − x)        σ = 10    Prandtl number
dy/dt = x(ρ − z) − y    ρ = 28    Rayleigh number
dz/dt = xy − βz         β = 8/3   Geometric factor
```

Discretised with Euler integration at `dt = 0.006`. Initial conditions `(−5.0, −6.5, 25.0)` place the trajectory on the attractor at t=0, eliminating the ~200-sample origin transit. X oscillates ≈ ±22, Y ≈ ±30, Z ≈ 0..50 (mean ≈ 23.5). All three signals are normalised to ≈ [−1, 1] before modulation; Z is recentred on its mean so all four delay modulators are zero-mean.

---

## Compiling

```bash
# JUCE plugin (VST3/AU)
faust2juce strange_attractor_reverb.dsp

# LV2
faust2lv2 strange_attractor_reverb.dsp

# VST2
faust2vst strange_attractor_reverb.dsp

# JACK standalone
faust2jack strange_attractor_reverb.dsp
```

**Browser:** paste into [https://faustide.grame.fr](https://faustide.grame.fr)

**Requirements:** Faust ≥ 2.50. No external dependencies.

---

## Notes for Developers

- `MAXD = 131072` — approximately 3 seconds at 44.1 kHz. Increase if using `Size > 2.0` or very low sample rates.
- The allpass interpolator includes a `1e-10` guard against divide-by-zero when the fractional delay is exactly zero.
- At `Chaos=1.0`, `Size=2.0`, d4 swings ±88 samples around its base. This is well within `MAXD` at standard sample rates.
- Chaos depth is independent of room size (fixed in v2). The two parameters are fully orthogonal.

---

## License

MIT License

Copyright (c) 2025 Claude (Anthropic)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
