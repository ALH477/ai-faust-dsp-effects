---
name: faust-dsp
description: >
  Use this skill whenever the user asks for Faust DSP code, audio effects, synthesizers,
  signal processors, or any .dsp file. Triggers include: phaser, flanger, reverb, delay,
  compressor, oscillator, filter, synthesizer, audio plugin, JSFX, VST, LV2, CLAP, JACK,
  Daisy, embedded audio, "write this in Faust", or any audio DSP implementation request.
  Also use when converting pseudocode or mathematical signal processing descriptions into
  Faust. Do NOT use for general audio programming in C++/Python/JUCE; those are code tasks
  that do not require this skill.
license: DeMoD Audio Systems internal reference
---

# Faust DSP Code Generation

## Philosophy: Math Before Code

**Always design the signal processing mathematics before writing a single line of Faust.**

The workflow is:
1. **Identify the DSP concept** — what physical/perceptual phenomenon are you modeling?
2. **Write the transfer function or difference equation** — in LaTeX/math notation
3. **Verify stability** — pole locations, DC gain, edge cases
4. **Map math to Faust primitives** — one primitive per mathematical operation
5. **Compose with Faust's algebra** — `:`, `<:`, `:>`, `~`, `par()`
6. **Add UI and metadata last**

Never start with UI sliders. Never write feedback before writing the transfer function.

---

## Faust Language Fundamentals

### The Signal Model

Faust processes *synchronous streams of samples*. Every expression is a function from N input streams to M output streams. The sample rate is available as `ma.SR` (a float).

```faust
// These are equivalent ways to write "pass signal through unchanged"
process = _;          // identity: 1 input → 1 output
process = _,_;        // stereo identity: 2 inputs → 2 outputs
```

### Core Composition Operators

| Operator | Name | Meaning |
|----------|------|---------|
| `A : B` | Sequential | Output of A feeds input of B. Ports must match. |
| `A , B` | Parallel | A and B side by side. Inputs and outputs concatenated. |
| `A <: B` | Split | Duplicates A's outputs to feed B's inputs (fan-out). |
| `A :> B` | Merge | Sums A's outputs to feed B's inputs (fan-in / mix). |
| `A ~ B` | Recursive | B's output (delayed 1 sample) feeds back into A's input. |

**Critical**: `~` always inserts exactly **one sample delay** in the feedback path. This makes all feedback causal. There is no way to create a zero-delay feedback loop in Faust — this is by design.

### The `par`, `seq`, `sum`, `prod` Iterators

```faust
// 4 filters in parallel, index k ∈ {0,1,2,3}
par(k, 4, someFilter(float(k)))

// 4 filters in series
seq(k, 4, someFilter(float(k)))

// Sum 4 signals
sum(k, 4, osc(baseFreq * pow(2.0, float(k))))

// Product of 4 signals (rare but valid)
prod(k, 4, envelope(float(k)))
```

**Always cast the loop index**: `float(k)` — it is an integer literal inside par/seq/sum.

### Arithmetic and Primitives

```faust
// All standard operators work sample-by-sample
x + y   x - y   x * y   x / y   x % y

// Power: use pow() or int exponentiation via ma library
pow(x, 2.0)        // x²
x * x              // also x²

// Comparisons return 0.0 or 1.0
x > y   x < y   x >= y   x <= y   x == y   x != y

// Conditionals
select2(cond, whenFalse, whenTrue)   // choose between two signals
select3(cond, a, b, c)               // three-way selector

// Min/max
min(x, y)   max(x, y)

// Type casting
int(x)   float(x)
```

### Unit Delay

```faust
x' // prime operator: delays x by exactly 1 sample
   // equivalent to x : mem
   // equivalent to x @ 1
```

### Variable Delay

```faust
x @ n        // delay x by n samples (integer, 0 to some max)
             // n can be a signal — time-varying delay

// For fractional (sub-sample) delays, use de library:
de.fdelay(maxDelay, delaySignal)    // 3rd-order Lagrange interpolation
de.sdelay(maxDelay, interp, d)      // smooth delay with interpolation factor
```

---

## Standard Library Reference

Always `import("stdfaust.lib")` — it loads all standard libraries under their prefixes.

```faust
import("stdfaust.lib");
// Now available: ma, si, fi, os, no, de, en, an, ba, pm, sp, ro, ve, dm, mi
```

### Most-Used Modules

#### `ma` — Math
```faust
ma.PI         // π
ma.SR         // sample rate (float)
ma.T          // 1/SR (sample period)
ma.decimal(x) // fractional part: x mod 1
ma.db2linear(x)  // 10^(x/20)
ma.linear2db(x)  // 20·log10(x)
```

#### `si` — Signals
```faust
si.smoo           // 1-pole smoother (≈20ms), use on ALL UI parameters
si.smooth(c)      // 1-pole smoother with explicit coefficient c
si.bus(n)         // n parallel wires
si.block(n)       // n parallel ground (silence) wires
```

#### `fi` — Filters (most important library)
```faust
fi.pole(b)           // H(z) = 1/(1 − b·z⁻¹), causal 1-pole IIR
fi.zero(b)           // H(z) = 1 − b·z⁻¹, 1-zero FIR
fi.tf1(b0,b1,a1)    // Direct-form I, 1st order: H(z)=(b0+b1z⁻¹)/(1+a1z⁻¹)
fi.tf2(b0,b1,b2,a1,a2)  // Direct-form II, 2nd order
fi.lowpass(n,fc)    // Butterworth LP, n=order, fc=cutoff Hz
fi.highpass(n,fc)   // Butterworth HP
fi.bandpass(n,fl,fu)// Butterworth BP
fi.peak_eq(gain,fc,Q) // Parametric EQ peak
fi.notch(fc,Q)      // Notch filter
```

**IMPORTANT**: `fi.tf1` and `fi.tf2` support **time-varying coefficients**. The coefficients can be signals that change each sample. This is the correct way to implement swept filters. Do not use `fi.lowpass` for sweeping — it recomputes internally and may alias.

#### `os` — Oscillators
```faust
os.osc(freq)         // sine oscillator (accurate, not cheap)
os.sawtooth(freq)    // bandlimited sawtooth
os.square(freq)      // bandlimited square
os.triangle(freq)    // bandlimited triangle
os.phasor(freq)      // raw phasor [0, 1) — best for custom waveforms
os.lf_sawpos(freq)   // low-frequency sawtooth [0, 1), NOT bandlimited
os.lf_trianglepos(f) // low-frequency triangle [0, 1)
```

For LFOs, **always use `os.lf_sawpos` or a manual phasor** — `os.phasor` is for audio-rate signals and has no advantage at LFO rates.

#### `no` — Noise
```faust
no.noise             // white noise U[-1,1]
no.pink_noise        // pink noise (1/f spectrum)
```

#### `de` — Delays
```faust
de.delay(maxN, n)        // integer delay, max buffer size maxN, delay n
de.fdelay(maxN, d)       // fractional delay (Lagrange 3rd-order)
de.sdelay(maxN, interp, d) // smooth delay (no clicks on modulation)
```

#### `en` — Envelopes
```faust
en.ar(a, r, t)           // attack-release (t = trigger signal)
en.adsr(a, d, s, r, t)   // full ADSR
en.adsre(a,d,s,r,t)      // exponential ADSR
```

#### `ba` — Basic utilities
```faust
ba.hz2midikey(freq)      // Hz → MIDI note number
ba.midikey2hz(n)         // MIDI note → Hz
ba.sec2samp(t)           // seconds → samples (= t * ma.SR)
ba.samp2sec(n)           // samples → seconds
ba.db2linear(x)          // decibels → linear
ba.linear2db(x)          // linear → decibels (careful: log of 0)
```

---

## UI Declaration Patterns

### Sliders (most common)
```faust
// hslider("label [meta:value]", default, min, max, step)
freq = hslider("Frequency [unit:Hz][style:knob]", 440.0, 20.0, 20000.0, 0.1) : si.smoo;
gain = hslider("Gain [unit:dB]", 0.0, -60.0, 12.0, 0.1) : si.smoo;

// Vertical slider (for plugin GUIs with vertical layout)
level = vslider("Level", 0.5, 0.0, 1.0, 0.001) : si.smoo;
```

**ALWAYS pipe sliders through `si.smoo`** unless the parameter controls something that must be instantaneous (like a bypass toggle). Zipper noise from unsmoothed parameters is unprofessional.

### Groups (for GUI organization)
```faust
// Horizontal group
freq = hslider("h:EQ/Frequency", ...);

// Vertical group  
gain = hslider("v:EQ/Gain", ...);

// Tab group
freq = hslider("t:EQ/Frequency", ...);

// Nested groups
freq = hslider("h:EQ/v:Band 1/Frequency", ...);
```

### Buttons and Checkboxes
```faust
bypass  = checkbox("Bypass");       // 0.0 or 1.0
trigger = button("Trigger");        // 1.0 while held, 0.0 otherwise
```

### Metadata annotations
```faust
// Style hints (host-dependent)
x = hslider("Name [style:knob]", ...);    // prefer knob rendering
x = hslider("Name [style:led]", ...);     // LED meter style
x = hslider("Name [style:numerical]", ...); // numeric entry

// Units (displayed in GUI)
x = hslider("Name [unit:Hz]", ...);
x = hslider("Name [unit:dB]", ...);
x = hslider("Name [unit:ms]", ...);

// Ordering (prefix number sorts in GUI)
x = hslider("[1] Rate", ...);
y = hslider("[2] Depth", ...);
```

---

## Building Blocks: Correct Faust Idioms

### Manual Phasor (best LFO base)
```faust
// φ[n] = (φ[n-1] + f/fs) mod 1
phasor(freq) = freq / float(ma.SR) : (+ : ma.decimal) ~ _;

// Use it:
lfo = phasor(0.5) : *(2.0 * ma.PI) : sin;   // sine LFO at 0.5 Hz
```

### 1st-Order All-Pass Filter (phaser building block)
```faust
// H(z) = (a - z⁻¹) / (1 - a·z⁻¹)     [textbook sign convention]
// Bilinear: t = tan(π·fc/fs),   a = (t-1)/(t+1)
apCoeff(fc) = (t - 1.0) / (t + 1.0)
with {
    t = tan(ma.PI * max(10.0, min(fc, float(ma.SR) * 0.48)) / float(ma.SR));
};
apf(a) = fi.tf1(0.0-a, 1.0, 0.0-a);    // b0=-a, b1=1, a1=-a
```

### 1-Pole Low-Pass Filter (analog-style)
```faust
// H(z) = (1-b)/(1-b·z⁻¹),   b = exp(-2π·fc/fs)
lpf1(fc) = _ * (1.0 - b) : fi.pole(b)
with { b = exp(0.0 - 2.0 * ma.PI * fc / float(ma.SR)); };
```

### Feedback With Saturation
```faust
// The ~ operator always adds 1-sample delay — this is causal and correct
// feedbackFn takes the output signal, returns the feedback contribution
effect = (+ : processing) ~ feedbackFn;

// Example: saturated delayed feedback
sat(x) = x * (27.0 + x*x) / (27.0 + 9.0*x*x);   // Padé tanh approximant
echo  = (+ : de.fdelay(88200, delayTime)) ~ (*(fbkLevel) : sat);
```

### Ornstein-Uhlenbeck Stochastic Process
```faust
// Models: tape wow/flutter, analog VCO drift, capacitor leakage
// SDE:  dX = -θ·X dt + σ dW
// Discrete: X[n] = α·X[n-1] + σ_d·w[n]
//   α   = exp(-θ/fs)          (mean-reversion coefficient)
//   σ_d = σ·√(1 - α²)        (noise amplitude for stationarity)
ouProcess(theta, sigma) = 0.0 : (_ ~ step)
with {
    alp  = exp(0.0 - theta / float(ma.SR));
    sigd = sigma * sqrt(1.0 - alp * alp);
    step(s) = s * alp + no.noise * sigd;
};
// theta: mean-reversion speed (Hz). Higher = faster return to zero.
// sigma: stationary standard deviation scale.
// Typical values for tape wow: theta=0.7, sigma=0.02–0.05
```

### Padé [3/2] tanh Approximant (feedback saturator)
```faust
// tanh(x) ≈ x·(27 + x²) / (27 + 9x²)
// Properties:
//   · Odd symmetry → zero DC in feedback path
//   · Unit slope at origin → linear at small signals
//   · |error| < 0.5% for |x| ≤ 2.0
//   · Bounded output → prevents feedback runaway
sat(x) = x * (27.0 + x*x) / (27.0 + 9.0*x*x);
```

### Raised-Cosine Window
```faust
// rcw(φ) = 0.5 - 0.5·cos(2π·φ),   φ ∈ [0,1)
// Used for Shepard/barberpole effects, crossfading, grain envelopes
rcw(phi) = 0.5 - 0.5 * cos(2.0 * ma.PI * phi);
```

### Biquad Wrapper (parametric EQ, resonant filter)
```faust
// Transposed Direct Form II biquad via fi.tf2
// H(z) = (b0 + b1·z⁻¹ + b2·z⁻²) / (1 + a1·z⁻¹ + a2·z⁻²)
biquad(b0,b1,b2,a1,a2) = fi.tf2(b0,b1,b2,a1,a2);

// Resonant LP (cookbook):
//   ω0 = 2π·fc/fs,  α = sin(ω0)/(2Q)
//   b0 = (1-cos(ω0))/2, b1 = 1-cos(ω0), b2 = b0
//   a0 = 1+α, a1 = -2cos(ω0)/a0, a2 = (1-α)/a0
```

### Stereo Mid/Side Encode-Decode
```faust
ms_enc = _, _ <: (+ : *(0.70710678)), (- : *(0.70710678));  // L,R → M,S
ms_dec = _, _ <: (+ : *(0.70710678)), (- : *(0.70710678));  // M,S → L,R  (same matrix)
```

### DC Blocking Filter
```faust
// Essential for any feedback path — prevents DC accumulation
dcblock = _ <: _, (: fi.pole(0.9999)) :> -;
// Or use the library version:
dc = fi.dcblockerat(35.0);   // -3dB at 35Hz
```

---

## File Structure Template

```faust
declare name        "EffectName";
declare author      "Author / Organization";
declare description "One-line description · key features";
declare version     "1.0";
declare license     "GPL-3.0";

// ┌──────────────────────────────────────────────────────────────────────────┐
// │  EffectName — Full Name                                                   │
// │  Author                                                                   │
// │                                                                            │
// │  Architecture:                                                             │
// │    · Key signal flow element 1                                             │
// │    · Key signal flow element 2                                             │
// └──────────────────────────────────────────────────────────────────────────┘

import("stdfaust.lib");


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  UI PARAMETERS                                                           ║
// ╚══════════════════════════════════════════════════════════════════════════╝

param1 = hslider("v:Effect/[1] Param1 [style:knob]", default, min, max, step) : si.smoo;


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  COMPONENT NAME                                                          ║
// ║                                                                          ║
// ║  Mathematical description of what this component does                   ║
// ║  Transfer function, difference equation, or invariant                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

component = ...;


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  PROCESS                                                                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝

process = ...;
```

---

## DeMoD Effect Design Standards

When producing effects under the DeMoD Audio Systems brand:

### Comment Block Style
Use box-drawing characters (`╔ ═ ╗ ║ ╚ ╝`) for section headers. Include the mathematical derivation of non-trivial components in comments. Comments serve as both documentation and as proof of correctness.

### Required Components for Any Modulated Effect
1. **OU drift** on all LFO instances — never bare `os.osc` or `os.lf_sawpos` for anything meant to sound organic
2. **Padé saturator** on all feedback paths — never raw `fi.pole` into feedback at high gains
3. **Bandwidth-limiting LPF** (fc ≈ 4–8 kHz) in feedback — models real analog circuit behavior
4. **`si.smoo`** on all UI parameters without exception

### Naming Conventions
- Effect files: `PascalCase.dsp` (e.g., `CassetteWraith.dsp`)
- Internal functions: `camelCase` (e.g., `apChain`, `stageFreq`, `ouDrift`)
- Constants: `ALL_CAPS` (e.g., `NVOX`, `DMIN`, `LOGR`)
- UI parameters: short `snake_case` or single words (e.g., `rate`, `fbk`, `wmix`, `sprd`)
- Loop indices in `par()`: single letter `k`, `i`, `n`

### Parameter Ranges (standard DeMoD defaults)
| Parameter | Range | Default | Notes |
|-----------|-------|---------|-------|
| Rate (LFO) | 0.01–4.0 Hz | 0.3 Hz | Use `[unit:Hz]` |
| Depth | 0.0–1.0 | 0.75 | Dimensionless |
| Feedback | 0.0–0.97 | 0.5 | Cap at 0.97, never 1.0 |
| Mix | 0.0–1.0 | 0.5 | Wet/dry |
| Wow | 0.0–1.0 | 0.25 | OU sigma scale |
| Spread | 0.0–1.0 | 0.5 | Stereo offset scale |

---

## Common Pitfalls and How to Avoid Them

### ❌ Recursive signal before `with`
```faust
// WRONG: referencing 'y' before it exists in scope
x = y + 1;
y = x * 2;

// CORRECT: use ~ for feedback
x = (_ + 1) ~ (_ * 2);
```

### ❌ Integer division when float is needed
```faust
// WRONG: 1/4 = 0 in Faust integer arithmetic
phase = k / NVOX;

// CORRECT: cast to float explicitly
phase = float(k) / float(NVOX);
```

### ❌ Unsmoothed parameter feeding a coefficient
```faust
// WRONG: zipper noise when knob moves
filter = fi.lowpass(1, hslider("fc", 1000, 20, 20000, 1));

// CORRECT: smooth first
fc     = hslider("fc", 1000, 20, 20000, 1) : si.smoo;
filter = fi.lowpass(1, fc);
```

### ❌ Feedback gain ≥ 1.0 without saturation
```faust
// WRONG: will blow up
dangerous = (+ : process) ~ *(1.0);

// CORRECT: saturate + cap below 1.0
safe = (+ : process) ~ (*(0.97) : sat);
```

### ❌ `ma.SR` used as int in arithmetic
```faust
// WRONG: type mismatch in some contexts
period = 1 / ma.SR;   // ambiguous integer/float

// CORRECT: be explicit
period = 1.0 / float(ma.SR);
```

### ❌ `de.fdelay` max buffer too small
```faust
// WRONG: if delay signal ever exceeds maxDelay samples, undefined behavior
de.fdelay(100, delayInSamples)   // 100 samples ≈ 2ms at 48kHz

// CORRECT: compute from seconds, add headroom
MAXD = int(0.1 * 192000) + 1;   // 100ms at max possible SR
de.fdelay(MAXD, delayInSamples)
```

### ❌ Using `os.phasor` as an LFO
```faust
// WRONG: os.phasor has BLEP anti-aliasing overhead — wasteful at LFO rates
lfo = os.phasor(0.5);

// CORRECT: manual accumulator, no antialiasing needed below ~50Hz
lfo = 0.5 / float(ma.SR) : (+ : ma.decimal) ~ _;
```

### ❌ Forgetting `par()` index is an integer
```faust
// WRONG: 'i' is int, 1/4 = 0
par(i, 4, voice(i/4))

// CORRECT
par(i, 4, voice(float(i) / 4.0))
```

---

## Compile Targets Quick Reference

```bash
# JACK standalone (Linux/Mac)
faust2jack MyEffect.dsp

# JACK with GTK GUI
faust2jack -gtk MyEffect.dsp

# LV2 plugin
faust2lv2 -gui MyEffect.dsp

# VST3
faust2vst MyEffect.dsp

# CLAP
faust2clap MyEffect.dsp

# Web Audio (browser)
faust2wasm MyEffect.dsp

# Daisy (embedded hardware)
faust2daisy MyEffect.dsp

# Pure Data external
faust2puredata MyEffect.dsp

# Max/MSP external
faust2max MyEffect.dsp

# Check syntax without compiling (fast iteration)
faust -e MyEffect.dsp   # expand libraries and print
faust -svg MyEffect.dsp # generate signal flow diagram as SVG
```

---

## Quality Checklist Before Delivering Code

- [ ] All UI sliders piped through `si.smoo`
- [ ] All feedback gains strictly < 1.0, preferably with saturation
- [ ] `float()` casts on all loop indices inside `par()` / `sum()`
- [ ] Delay buffer sizes computed from worst-case SR (e.g., 192000), not hardcoded samples
- [ ] DC blocking on any feedback path that processes low-frequency content
- [ ] `declare name`, `author`, `description`, `version`, `license` metadata present
- [ ] Every non-trivial component has a comment explaining the transfer function or mathematical basis
- [ ] `process` has correct port count (stereo = 2 in, 2 out)
- [ ] Tested mentally for the case where all parameters are at their extremes (max feedback, max depth, etc.)
