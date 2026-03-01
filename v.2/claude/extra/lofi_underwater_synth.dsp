// ===========================================================
//  Lo-Fi Underwater Synth  —  v3
//  Physical + Mathematical DSP Modeling in Faust
//
//  Signal chain:
//    Excitation → Karplus-Strong → Modal resonators
//    → DC block → Underwater LPF (α∝f², LFO-modulated)
//    → Tape saturation → Wow/flutter → Bitcrusher
//    → mix pink noise → Zita reverb → stereo out
// ===========================================================

import("stdfaust.lib");

// -----------------------------------------------------------
//  UI — grouped for cleaner plugin layout
// -----------------------------------------------------------

sourceGroup(x)  = hgroup("[1] Source",  x);
filterGroup(x)  = hgroup("[2] Filter",  x);
reverbGroup(x)  = hgroup("[3] Reverb",  x);
lofiGroup(x)    = hgroup("[4] Lo-Fi",   x);

// Source / Excitation
freq       = sourceGroup(hslider("[1] Frequency [unit:Hz] [scale:log]", 220, 30, 2000, 0.5)) : si.smoo;
gate       = sourceGroup(button("[2] Gate"));
exciteLen  = sourceGroup(hslider("[3] Decay [unit:samples]", 512, 32, 4096, 1));
exciteGain = sourceGroup(hslider("[4] Gain", 0.8, 0, 1, 0.01)) : si.smoo;
ksDecay    = sourceGroup(hslider("[5] KS Damp", 0.05, 0, 0.5, 0.001)) : si.smoo;

// Underwater filter + LFO
uwCutoff      = filterGroup(hslider("[1] Cutoff [unit:Hz] [scale:log]", 600, 80, 1500, 1)) : si.smoo;
uwDepth       = filterGroup(hslider("[2] Depth", 0.7, 0, 1, 0.01)) : si.smoo;
filterLFORate = filterGroup(hslider("[3] LFO Rate [unit:Hz]", 0.2, 0.01, 2, 0.01));
filterLFODep  = filterGroup(hslider("[4] LFO Depth [unit:Hz]", 60, 0, 300, 1)) : si.smoo;

// Reverb
revRoom = reverbGroup(hslider("[1] Room Size", 0.6, 0, 1, 0.01)) : si.smoo;
revWet  = reverbGroup(hslider("[2] Mix",       0.45, 0, 1, 0.01)) : si.smoo;

// Lo-Fi chain
satDrive   = lofiGroup(hslider("[1] Tape Drive",   1.5,   1, 10,   0.1))    : si.smoo;
wowRate    = lofiGroup(hslider("[2] Wow Rate [unit:Hz]", 0.4, 0.05, 3, 0.01));
wowDepth   = lofiGroup(hslider("[3] Wow Depth",    0.003, 0, 0.02, 0.0001)) : si.smoo;
crushBits  = lofiGroup(hslider("[4] Bit Depth",    10,    4, 16,   1));
noiseLevel = lofiGroup(hslider("[5] Noise Level",  0.04,  0, 0.3,  0.001))  : si.smoo;
outGain    = lofiGroup(hslider("[6] Output Gain",  0.7,   0, 1,    0.01))   : si.smoo;

// -----------------------------------------------------------
//  SECTION 1 — EXCITATION
//
//  ba.impulsify: converts gate button → single-sample impulse
//  on each rising edge (built-in, cleaner than manual x@1 diff).
//
//  One-pole feedback on the impulse creates an exponential
//  decay envelope:  y[n] = δ[n] + coeff · y[n-1]
//  where coeff = e^(−1/τ), τ = exciteLen in samples.
//  This gives a natural-sounding, click-free burst — matching
//  the original KS specification — instead of a hard rectangular window.
//
//  max(1.0, exciteLen) guards against div-by-zero if slider hits 0.
// -----------------------------------------------------------

exciteCoeff = exp(-1.0 / max(1.0, exciteLen));
excitation  = no.noise * exciteGain
            * (gate : ba.impulsify : + ~ *(exciteCoeff));

// -----------------------------------------------------------
//  SECTION 2 — KARPLUS-STRONG RESONATOR
//
//  FIX (v2→v3): de.delay() truncates to integer delay lengths,
//  causing pitch errors up to 40 cents at high frequencies.
//  de.fdelay() uses linear interpolation for fractional delays,
//  giving sub-cent pitch accuracy across the full frequency range.
//
//  Delay compensation: the loop filter (one-zero averager + mem)
//  has a fixed group delay of 1.5 samples, so we subtract that
//  from the target delay length.  max(1.0,...) prevents illegal
//  zero or negative delay values.
//
//  Loop filter:  H(z) = (1 + z⁻¹) / 2 · (1 − damp)
//  DC gain = (1 − damp) < 1  →  stable decay guaranteed.
// -----------------------------------------------------------

ksLoopFilter(damp) = _ <: (_, mem) :> _ : /(2.0) : *(1.0 - damp);

ksDelayLen = max(1.0, ma.SR / freq - 1.5);

karplusStrong(damp) =
    (+ : de.fdelay(65536, ksDelayLen)) ~ ksLoopFilter(damp);

// -----------------------------------------------------------
//  SECTION 3 — MODAL RESONATORS
//
//  Inharmonic partial ratios for a cylindrical metal shell:
//    mode 1: 1.00 × f  (fundamental)
//    mode 2: 2.76 × f  (first inharmonic)
//    mode 3: 5.40 × f  (second inharmonic)
//
//  Mode frequencies are clamped to 45% of Nyquist (ma.SR*0.45)
//  to prevent aliasing or filter instability at lower sample rates.
// -----------------------------------------------------------

safeMode(ratio, q, amp) =
    fi.resonbp(min(freq * ratio, ma.SR * 0.45), q, amp);

modalResonators =
    _ <: safeMode(1.00, 12, 0.60),
         safeMode(2.76, 10, 0.35),
         safeMode(5.40,  8, 0.15)
    :> _;

// -----------------------------------------------------------
//  SECTION 4 — UNDERWATER ACOUSTIC FILTER
//
//  Physical model: α(f) ∝ f² (viscosity + relaxation absorption).
//  Stage 1: 4th-order Butterworth LPF at uwCutoff.
//  Stage 2: wet/dry blend with an extra 2nd-order LPF at
//           cutoff/2, weighted by uwDepth, approximating
//           the steeper f²-shaped attenuation with depth.
//
//  Cutoff LFO: slow band-limited noise (0.01–2 Hz) modulates
//  the cutoff for the "breathing" water movement described
//  in the original spec.  Clamped to min 80 Hz for stability.
// -----------------------------------------------------------

filterLFO   = no.lfnoiseN(2, filterLFORate) * filterLFODep;
uwCutoffMod = max(80.0, uwCutoff + filterLFO);
halfCutoff  = uwCutoffMod * 0.5;

// Hoist filter stages as named top-level processors.
// Inline signal expressions (halfCutoff, uwDepth) inside <: parallel blocks
// cause the parser to steal ':' tokens into fi.lowpass argument lists,
// producing the "outputs [1] must equal inputs [2]" arity error.
// Using plain identifiers inside <: avoids all precedence ambiguity.
uwLP4    = fi.lowpass(4, uwCutoffMod);
uwLP2wet = fi.lowpass(2, halfCutoff) : *(uwDepth);
uwLP2dry = *(1.0 - uwDepth);

underwaterFilter = uwLP4 <: (uwLP2wet, uwLP2dry) :> _;

// -----------------------------------------------------------
//  SECTION 5 — LO-FI CHAIN
// -----------------------------------------------------------

// Tape saturation: ma.tanh is the correct namespaced form.
// Bare 'tanh' in global scope causes BoxIdent; 'ma.tanh' resolves cleanly
// through the ffunction wrapper in the ma namespace.
tapeSat(drive, x) = ma.tanh(x * drive) / drive;

// Wow & flutter: fractional delay modulated by band-limited
// noise LFO.  Base delay 100 samples (~2.3 ms) with ±50 sample
// maximum swing.  wowDepth smoothed to prevent LFO discontinuities.
wowLFO     = no.lfnoiseN(3, wowRate) * wowDepth;
wowFlutter = de.fdelay(2048, 100.0 + 50.0 * wowLFO);

// Bitcrusher: quantise to N bits.
// floor and pow are Faust built-in primitives — safe to use directly.
// 'with' evaluates scale once rather than calling pow twice per sample.
bitcrush(bits, x) = floor(x * scale) / scale
    with { scale = pow(2.0, bits - 1.0); };

// Pink-noise ambient layer (100 Hz – 1 kHz).
// Models distant biological noise, water currents, bubbles.
pinkLayer =
    no.pink_noise
    : fi.highpass(2, 100.0)
    : fi.lowpass(2,  1000.0)
    : *(noiseLevel);

// -----------------------------------------------------------
//  SECTION 6 — REVERB  (Zita / FDN, stereo out)
//
//  FIX (v2→v3): rdel is in MILLISECONDS, not seconds.
//  Previous value 0.02 = 0.02 ms ≈ 1 sample (no pre-delay).
//  Corrected to 20.0 ms to simulate the surface reflection
//  described in the original spec.
//
//  re.zita_rev1_stereo(rdel, f1, f2, t60dc, t60m, fsmax)
//    rdel  — pre-delay in ms        (20 ms = surface reflection)
//    f1    — low shelf crossover Hz  (tied to uwCutoff * 0.4)
//    f2    — high shelf crossover Hz (tied to uwCutoffMod)
//    t60dc — T60 at DC in seconds
//    t60m  — T60 at mid in seconds
//    fsmax — max expected sample rate (use ma.SR for safety)
//
//  Takes 2 inputs → 2 outputs (stereo).
//
//  reverbMix(wet): mono → stereo wet/dry blend.
//  Arity trace:
//    _ <: (_,_,_)              → 3 copies
//    (reverb : scale), (dry)  → wetL, wetR, dryL, dryR  [4]
//    ro.interleave(2,2)        → wetL, dryL, wetR, dryR  [4]
//    _+_, _+_                  → L, R                    [2]
// -----------------------------------------------------------

t60dc = revRoom * 6.0 + 1.0;
t60m  = revRoom * 3.0 + 0.5;

underwaterReverb =
    re.zita_rev1_stereo(20.0, uwCutoff * 0.4, uwCutoffMod,
                        t60dc, t60m, ma.SR);

reverbMix(wet) =
    _ <: (_,_,_)
    : ( ((_,_) : underwaterReverb : (*(wet), *(wet)))
      , (_ <: (*(1.0-wet), *(1.0-wet)))
      )
    : ro.interleave(2,2)
    : (_+_, _+_);

// -----------------------------------------------------------
//  FULL SIGNAL CHAIN
// -----------------------------------------------------------

synthMono =
    excitation
    : karplusStrong(ksDecay)
    : modalResonators
    : fi.dcblocker        // prevent DC buildup in KS feedback loop
    : underwaterFilter
    : tapeSat(satDrive)
    : wowFlutter
    : bitcrush(crushBits);

process =
    (synthMono, pinkLayer) :> _   // merge: synth + ambient noise
    : reverbMix(revWet)            // stereo wet/dry reverb
    : (*(outGain), *(outGain));    // master output gain
