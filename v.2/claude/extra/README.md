# Abyssal Pluck

**A lo-fi underwater physical modelling synthesiser written in Faust DSP**

Abyssal Pluck simulates the sound of a plucked metal object submerged in deep water — the muffled resonance of a hull, a drowned bell, a corroded pipe — then degrades it through tape saturation, pitch wobble, and bitcrushing until it sits comfortably in a lo-fi mix. Every stage is grounded in acoustic physics or DSP mathematics rather than preset approximations.

---

## Signal Chain

```
Gate trigger
    │
    ▼
Exponential noise burst (excitation)
    │
    ▼
Karplus-Strong resonator      ← digital waveguide, fractional delay
    │
    ▼
Modal resonators × 3          ← inharmonic shell modes (1.00×, 2.76×, 5.40×)
    │
    ▼
DC blocker
    │
    ▼
Underwater acoustic filter    ← α(f) ∝ f², LFO-modulated cutoff
    │
    ▼
Tape saturation               ← ma.tanh soft-clipper
    │
    ▼
Wow & flutter                 ← noise-LFO fractional delay
    │
    ▼
Bitcrusher                    ← N-bit quantisation
    │
    + ← Pink noise (100 Hz – 1 kHz ambient layer)
    │
    ▼
Zita reverb (stereo)          ← FDN with 20 ms pre-delay
    │
    ▼
Master output gain
```

---

## DSP Design

### Excitation

The Gate button triggers a single-sample impulse via `ba.impulsify`. This feeds a one-pole IIR feedback loop:

```
y[n] = δ[n] + coeff · y[n−1],   coeff = e^(−1/τ)
```

where τ is the **Decay** slider in samples. The result is a click-free exponential noise burst — the canonical Karplus-Strong excitation — rather than a hard rectangular window that would produce an audible transient at its end.

### Karplus-Strong Resonator

A digital waveguide string: a fractional delay line of length `SR/f` with a one-zero averaging low-pass filter in the feedback loop.

```
H_loop(z) = (1 + z⁻¹) / 2 · (1 − damp)
```

`de.fdelay` (linear interpolation) is used rather than `de.delay` (integer truncation) to avoid pitch errors that reach 40 cents at 2000 Hz. The loop filter group delay of 1.5 samples is subtracted from the target delay length to keep tuning accurate.

### Modal Resonators

Three second-order bandpass filters at inharmonic frequency ratios typical of a cylindrical metal shell:

| Mode | Ratio | Q  | Weight |
|------|-------|----|--------|
| 1    | 1.00× | 12 | 0.60   |
| 2    | 2.76× | 10 | 0.35   |
| 3    | 5.40× |  8 | 0.15   |

All mode frequencies are clamped to 45% of Nyquist to prevent instability at lower sample rates.

### Underwater Acoustic Filter

Water attenuates sound with an absorption coefficient α(f) ∝ f² — high frequencies are killed far more aggressively than low. This is modelled in two stages:

- **Stage 1** — 4th-order Butterworth LPF at the main cutoff (default 600 Hz, range 80–1500 Hz)
- **Stage 2** — wet/dry blend between a 2nd-order LPF at half that cutoff and the dry signal, weighted by the **Depth** parameter, which adds the steeper f²-shaped tilt

A band-limited noise LFO (0.01–2 Hz) continuously modulates the cutoff frequency, giving the subtle breathing movement of real underwater acoustics. The modulated cutoff is also shared with the reverb's high-frequency shelf so the tail breathes in sync.

### Tape Saturation

`ma.tanh` soft-clipping with adjustable drive. The signal is amplified by the drive factor before the clipper and divided by the same factor after, preserving approximate level while adding harmonics.

### Wow & Flutter

A fractional delay line (`de.fdelay`) modulated by a band-limited noise LFO (`no.lfnoiseN` order 3). The base delay is 100 samples (~2.3 ms at 44.1 kHz) with a maximum swing of ±50 samples. Both the rate and depth parameters are smoothed to prevent clicks on adjustment.

### Bitcrusher

Quantises the signal to N bits using `floor` with a power-of-two scale factor. At 10 bits (default) the degradation is subtle; at 4 bits it becomes harsh and lo-fi.

### Pink Noise Layer

Bandpassed `no.pink_noise` (100 Hz – 1 kHz) models the ambient acoustic texture of real underwater recordings — distant biological noise, current turbulence, micro-bubble activity.

### Reverb

`re.zita_rev1_stereo` — a high-quality feedback delay network reverb with a 20 ms pre-delay simulating the first surface reflection. T60 decay times scale with the Room Size parameter (1–7 seconds at DC, 0.5–3.5 seconds at mid). The reverb's high-frequency shelf tracks the modulated underwater filter cutoff.

---

## Parameters

### Source
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Frequency | 30–2000 Hz (log) | 220 Hz | Fundamental pitch of the resonator |
| Gate | — | — | Trigger button — press to pluck |
| Decay | 32–4096 samples | 512 | Length of the noise burst envelope |
| Gain | 0–1 | 0.8 | Excitation amplitude |
| KS Damp | 0–0.5 | 0.05 | Loop filter loss — higher = faster decay |

### Filter
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Cutoff | 80–1500 Hz (log) | 600 Hz | Underwater LPF cutoff |
| Depth | 0–1 | 0.7 | f² absorption tilt — higher = deeper water |
| LFO Rate | 0.01–2 Hz | 0.2 Hz | Speed of cutoff modulation |
| LFO Depth | 0–300 Hz | 60 Hz | Amount of cutoff modulation |

### Reverb
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Room Size | 0–1 | 0.6 | Scales T60 decay times |
| Mix | 0–1 | 0.45 | Wet/dry balance |

### Lo-Fi
| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Tape Drive | 1–10 | 1.5 | Saturation amount |
| Wow Rate | 0.05–3 Hz | 0.4 Hz | Speed of pitch wobble |
| Wow Depth | 0–0.02 | 0.003 | Amount of pitch wobble |
| Bit Depth | 4–16 bits | 10 | Quantisation resolution |
| Noise Level | 0–0.3 | 0.04 | Ambient noise floor |
| Output Gain | 0–1 | 0.7 | Master output level |

---

## Building

### Try it instantly in the browser

Paste `lofi_underwater_synth.dsp` into the [Faust Web IDE](https://faustide.grame.fr), press **Run**, then press **Gate**.

### Compile to LV2 (Linux)

```bash
faust2lv2 lofi_underwater_synth.dsp
```

### Compile to VST2

```bash
faust2vst lofi_underwater_synth.dsp
```

### Compile to Audio Unit (macOS)

```bash
faust2au lofi_underwater_synth.dsp
```

### Compile to JACK standalone

```bash
faust2jack lofi_underwater_synth.dsp
```

Requires [Faust](https://faust.grame.fr) and the appropriate SDK for your target format.

---

## Faust Gotchas Encountered

A few non-obvious Faust behaviours discovered during development, documented here for future reference.

**`tanh` causes `BoxIdent` when used bare.** `stdfaust.lib` imports `maths.lib`, which defines `tanh` as an `ffunction` foreign C box in the global namespace. Writing `_ : tanh` hits this definition and fails. The fix is `ma.tanh` — the namespaced reference resolves through the library object rather than colliding with the global name.

**Inline signal expressions inside `<:` steal `:` tokens.** When a `fi.lowpass` frequency argument contains operators (e.g. `uwCutoffMod * 0.5`), Faust's parser consumes the `: *(scale)` that follows as part of the argument list rather than as sequential composition after the filter. The fix is to define the signal expression as a named top-level definition and reference it by identifier inside the `<:` block.

**`de.delay` gives wrong pitch.** It truncates delay length to integers, producing pitch errors up to 40 cents at high frequencies. Use `de.fdelay` for fractional (interpolated) delay.

**`rdel` in `re.zita_rev1_stereo` is in milliseconds**, not seconds. `0.02` = 0.02 ms ≈ 1 sample, not 20 ms.

---

## License

MIT
