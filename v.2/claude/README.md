# MYCELIUM

**Organic Bio-Resonant Mycelium Network — FAUST LV2 Audio Effect**

*Author: Claude (Anthropic)*
*License: MIT*
*Version: 1.4*

---

## Concept

Mycorrhizal networks are the vast underground fungal webs that silently connect entire forest ecosystems — relaying chemical and electrical signals through kilometres of interwoven hyphae. MYCELIUM maps this biology directly onto audio signal processing.

Six resonant nodes (hyphal tips) exchange vibrational energy through a chaos-modulated coupling matrix, driven by a real-time Lorenz attractor running at full audio rate — ensuring no two decays are ever identical. A nonlinear tube-inspired waveshaper acts as the metabolic engine, injecting harmonic nutrients that feed the entire resonator ecosystem.

The result is an effect that is, in the most literal sense, **alive**.

---

## Sonic Character

On **percussive transients**: a metallic, crystalline bloom that breathes and wanders micro-tonally before dissolving into the noise floor.

On **sustained tones**: lush, evolving spectral clouds with phantom inter-resonator beating and continuously shifting overtone halos.

**High Coupling** pushes the network toward shimmering near-feedback — a vast cavern of coupled resonance.

**Low Coupling** yields pristine, crystallographically pure decay trails.

The **Shimmer** layer adds octave-and-fifth sympathetic resonances reminiscent of prepared piano struck behind the bridge, or bowed crotales.

---

## Building

### Prerequisites

- FAUST 2.0+ (`faust2lv2` in PATH)
- g++ with C++11 support

### Compile to LV2

```bash
faust2lv2 mycelium.dsp -std=c++11 -fvisibility=hidden -O3
```

This produces a `mycelium.lv2/` directory. Copy it to your LV2 plugin path:

```bash
cp -r mycelium.lv2 ~/.lv2/
```

### Other targets

```bash
# JACK standalone
faust2jack mycelium.dsp

# VST2 (requires vestige headers)
faust2vst mycelium.dsp

# JUCE-based VST3/AU
faust2juce mycelium.dsp

# Web Audio (browser)
faust2webaudiowasm mycelium.dsp

# Preview in GUI (quickest way to hear it)
faust2jaqt mycelium.dsp && ./mycelium
```

---

## Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| **Drive** | 0.0 – 1.0 | 0.30 | Input saturation. Asymmetric tube-style waveshaper injects odd and even harmonics into the resonator network. |
| **Root Freq** | 40 – 2000 Hz | 220 Hz | Fundamental frequency anchor. All six resonator nodes fan out from this pitch via golden-ratio intervals. |
| **Spread** | 0.0 – 1.0 | 0.50 | Golden-ratio frequency spread. 0 collapses all nodes to unison; 1 fans them across multiple octaves. |
| **Decay** | 0.05 – 8.0 s | 2.5 s | Network ring-out time. Resonator Q is derived automatically so every node decays in exactly this duration. |
| **Chaos** | 0.0 – 1.0 | 0.20 | Lorenz attractor pitch modulation depth. Introduces organic micro-pitch drift — unique to every note played. |
| **Coupling** | 0.0 – 0.70 | 0.25 | Cross-node energy transfer. Higher values create shimmering feedback resonance approaching self-oscillation. |
| **Shimmer** | 0.0 – 1.0 | 0.15 | Sympathetic overtone layer. Adds 2nd and 3rd harmonic resonant halos with shorter decay than the primary nodes. |
| **Breathe** | 0.01 – 4.0 Hz | 0.30 Hz | Lorenz evolution speed. Slow = glacial spectral drift. Fast = flickering timbral turbulence. |
| **Tone** | −1.0 – +1.0 | 0.0 | Spectral tilt. Negative = dark and warm (low-pass). Positive = bright and airy (high-pass). |
| **Mix** | 0.0 – 1.0 | 0.70 | Dry/wet balance. |

---

## Sweet Spots

| Context | Drive | Chaos | Decay | Coupling | Mix | Notes |
|---------|-------|-------|-------|----------|-----|-------|
| Ambient / drone | 0.30 | 0.20 | 4.0 s | 0.30 | 0.80 | Breathe 0.15 Hz for slowest drift |
| Prepared piano | 0.50 | 0.25 | 2.0 s | 0.40 | 0.65 | Spread 0.60 for metallic inharmonicity |
| Percussion bloom | 0.60 | 0.30 | 0.5 s | 0.50 | 0.75 | Short decay, high coupling for dense tail |
| Pad augmentation | 0.20 | 0.15 | 4.0 s | 0.20 | 0.55 | Shimmer 0.40, Tone −0.3 for warmth |
| Chaotic landscape | 0.40 | 0.50 | 3.0 s | 0.65 | 0.90 | Breathe 2.0 Hz — never the same twice |
| Field recording FX | 0.10 | 0.35 | 6.0 s | 0.25 | 0.85 | Spread 0.80 for wide spectral cloud |

---

## Architecture

```
Input
  │
  ├─── ×(1 − mix) ──────────────────────────────────────────┐
  │                                                          │
  └─── tubeSat(drive)                                        │
         │                                                   ▼
         └─── resonNetwork ──── tiltFilter ──── ×(mix) ───(+)──► Output
                │
                │   ┌─────────────────────────────────────┐
                │   │  Lorenz Attractor (audio rate)       │
                │   │  lorenzStep ~ si.bus(3)              │
                │   │  lx, ly, lz ── chaos modulation      │
                │   └─────────────────────────────────────┘
                │
                ▼
         ┌─────────────────────────────────────────────────┐
         │  Resonator Bank                                  │
         │  6× fi.resonbp on golden-ratio frequency grid   │
         │  Q = π × f × T60   (auto-scaled decay)          │
         │  + shimmer: 2nd & 3rd harmonic sympathetics     │
         └─────────────────────────────────────────────────┘
                │
         ┌──────┴──────┐
         │  Coupling   │  +~(resoBank : lowpass : ×gain)
         │  Feedback   │  one-sample delayed cross-node energy
         └─────────────┘
```

### Key DSP Techniques

**Lorenz Attractor** — Explicit Euler integration of the Lorenz (1963) strange attractor at full audio rate. `lorenzStep ~ si.bus(3)` creates a 0-input, 3-output autonomous generator. A one-sample impulse at t=0 perturbs the system off the trivial fixed point; the chaotic butterfly orbit sustains itself indefinitely. The three independent axes (x, y, z) modulate separate resonator nodes, ensuring no two nodes share the same micro-pitch trajectory.

**Golden-Ratio Resonator Grid** — Six bandpass nodes spaced above and below `rootFreq` using φ (1.618...) exponents, creating a beautiful inharmonic but musically coherent frequency constellation. Q is derived from the T60 decay time relationship Q ≈ π × f × T₆₀, so every node — regardless of pitch — decays in exactly `decayT` seconds.

**Coupling Feedback** — The summed resonator output is low-pass filtered, scaled by `coupling × 0.97`, and fed back into the bank's input via FAUST's `+~` operator (inherent one-sample delay). This approximates the mycelium's cross-node chemical signalling: every node indirectly receives decayed energy from all others, creating sympathetic beating and cascading resonance.

**Asymmetric Tube Saturation** — The waveshaper applies both a linear gain term `(1 + drive×14)×x` (odd harmonics) and a quadratic bias `drive×0.05×x²` (even harmonics for warmth), normalised through `x/(1+|x|)` softclip — bounded and smooth at all drive levels.

---

## License

```
MIT License

Copyright (c) 2025 Claude (Anthropic)

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
```

---

*"The forest is not a collection of trees. It is a single organism, whispering."*
