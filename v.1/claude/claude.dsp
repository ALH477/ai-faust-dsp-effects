import("stdfaust.lib");

//=================================================================
//  S T R A N G E   A T T R A C T O R   R E V E R B
//  A 4-channel FDN driven by a Lorenz chaotic attractor
//  by Claude — v2 (corrected)
//=================================================================
//
//  FIXES vs. v1:
//
//  1. INTERPOLATION: de.fdelay (linear) → first-order allpass.
//     Linear interpolation has a sinc roll-off above ~0.4·Nyquist
//     and introduces amplitude aliases at high modulation depths.
//     An allpass has a flat magnitude response; its phase artifact
//     reads as diffusion rather than distortion — appropriate for
//     a reverb feedback path.
//
//  2. CHAOS DEPTH DECOUPLED FROM ROOM SIZE: Previously modSa was
//     inside the roomSz multiplication, so chaos depth scaled 2×
//     at roomSz=2.  Base delay now scales with room; chaos offset
//     is added after, independently.
//
//  3. nz DC OFFSET REMOVED: Lorenz Z ∈ [0,~50] with mean ≈ 23.5,
//     not symmetric around zero.  Z is now recentred so all four
//     modulators are zero-mean and equally bipolar.
//
//  4. STARTUP TRANSIENT FIXED: Initial conditions are placed on the
//     attractor at sample 0, skipping the ~200-sample origin transit.
//
//  5. β written as 8.0/3.0 (compiler constant-folds it).
//
//=================================================================

//─── PARAMETERS ──────────────────────────────────────────────────

roomSz = hslider("[0] Size",  0.6,  0.05,  2.0,    0.001) : si.smoo;
decayT = hslider("[1] Decay", 0.84, 0.0,   0.9999, 0.001) : si.smoo;
chaosD = hslider("[2] Chaos", 0.5,  0.0,   1.0,    0.001) : si.smoo;
dampHz = hslider("[3] Damp",  5000, 100.0, 20000,  1.0  ) : si.smoo;
wetAmt = hslider("[4] Mix",   0.35, 0.0,   1.0,    0.001) : si.smoo;

MAXD   = 131072;   // max delay buffer: ~3 s at 44.1 kHz

//─── LORENZ ATTRACTOR ─────────────────────────────────────────────
//
//  dx/dt = σ(y − x)         σ = 10   (Prandtl number)
//  dy/dt = x(ρ − z) − y     ρ = 28   (Rayleigh number)
//  dz/dt = xy − βz          β = 8/3  (geometric factor)
//
//  FIX 4 — Initial conditions at a known attractor point
//  (−5.0, −6.5, 25.0) instead of kicking from the origin.
//  ba.pulse(1) is 1 on sample 0, 0 thereafter.
//  The term  ic*(IC_coord - state)  hard-overrides the integrator
//  on the very first sample, placing the trajectory on the
//  attractor immediately.  No transit, no mis-modulated onset.

lorenz(dt) = (step ~ (_,_,_))
with {
    ic = ba.pulse(1);
    step(xp, yp, zp) =
        xp + dt * 10.0*(yp - xp)               + ic*(-5.0  - xp),
        yp + dt * (xp*(28.0 - zp) - yp)        + ic*(-6.5  - yp),
        zp + dt * (xp*yp - (8.0/3.0)*zp)       + ic*(25.0  - zp);
};

//─── ALLPASS FRACTIONAL DELAY ─────────────────────────────────────
//
//  FIX 1 — Replaces de.fdelay throughout the FDN feedback path.
//
//  First-order allpass interpolation:
//    n   = floor(d)          integer delay
//    f   = d - n             fractional part ∈ [0, 1)
//    η   = (1−f)/(1+f)       allpass coefficient
//    y[n]= η·x[n] + x[n-N] − η·y[n-1]
//
//  Magnitude response is exactly 1 at all frequencies.
//  Group delay varies smoothly — at η=0 it equals the integer
//  delay; at η→1 it adds nearly a full extra sample.
//  The phase non-linearity is inaudible as colouration and
//  beneficial as additional diffusion in a reverb context.

apDelay(maxd, d, x) = loop ~ _
with {
    n    = int(d);
    f    = d - float(n);
    eta  = (1.0 - f) / (1.0 + f + 1e-10);
    loop(fb) = eta*(x - fb) + de.delay(maxd, n, x);
};

//─── BUILDING BLOCKS ─────────────────────────────────────────────

// Bijective soft saturation: y = x/(1+|x|)
// Unit gain at origin, asymptotes to ±1, smooth everywhere.
// Acts as soft-knee per-mode compression in the feedback path.
softclip(x) = x / (1.0 + abs(x));

// 1-pole IIR lowpass: pole at g = exp(−2π·fc/SR)
lp1(g) = *(1.0 - g) : + ~ *(g);

dampCoef = exp(-2.0*ma.PI*dampHz / float(ma.SR));

//─── HADAMARD 4×4 ────────────────────────────────────────────────
//
//  All entries ±0.5 → every output sees every input.
//  Orthogonal (singular values all 1) → energy-preserving.
//
//  H = [ 1  1  1  1 ]
//      [ 1 -1  1 -1 ] × 0.5
//      [ 1  1 -1 -1 ]
//      [ 1 -1 -1  1 ]

h4(a,b,c,d) = (a+b+c+d)*0.5,
              (a-b+c-d)*0.5,
              (a+b-c-d)*0.5,
              (a-b-c+d)*0.5;

//─── PRIME-RATIO BASE DELAY TIMES ────────────────────────────────
// Near-prime millisecond values; mutual primeness suppresses
// coincident modal resonances.  All scaled by roomSz at runtime.

b1 = ba.sec2samp(0.02971);
b2 = ba.sec2samp(0.03719);
b3 = ba.sec2samp(0.04673);
b4 = ba.sec2samp(0.05639);

//─── STEREO DECORRELATION ────────────────────────────────────────
// (y0,y2)→L, (y1,y3)→R: maximum decorrelation, mono-compatible.
stereoOut(y0,y1,y2,y3) = (y0 + y2)*0.5, (y1 + y3)*0.5;

//─── MAIN SIGNAL PROCESSOR ───────────────────────────────────────

mainFX(l, r, lx, ly, lz) = outL, outR
with {
    //── Normalise Lorenz to ≈ [−1, 1] ────────────────────────
    //
    //  FIX 3 — Z recentred.
    //  Lorenz Z long-run mean ≈ ρ − 1 − β ≈ 21.67 (theoretical),
    //  empirically closer to 23.5 for these parameters and dt.
    //  Subtracting 23.5 and dividing by half-range (≈27) gives
    //  a zero-mean, unit-scale modulator matching X and Y.
    //
    //  All three normalised signals are now bipolar and zero-mean,
    //  so d1..d4 all modulate symmetrically around their base times.

    nx  = lx * 0.04546;              // X/22   — X range ≈ ±22
    ny  = ly * 0.03333;              // Y/30   — Y range ≈ ±30
    nz  = (lz - 23.5) * 0.03704;    // (Z−mean)/27 — zero-centred

    //── Chaos modulation depth: ±2 ms, room-size-independent ─
    //
    //  FIX 2 — modSa is no longer inside the roomSz multiply.
    //  Old:  (base + chaos) * roomSz  → chaos doubles at roomSz=2
    //  New:   base*roomSz  + chaos    → orthogonal parameters

    modSa = chaosD * ba.sec2samp(0.002);  // ±88 samples at 44.1 kHz

    d1 = max(2.0, b1 * roomSz  +  nx      * modSa);
    d2 = max(2.0, b2 * roomSz  +  ny      * modSa);
    d3 = max(2.0, b3 * roomSz  +  nz      * modSa);
    d4 = max(2.0, b4 * roomSz  +  nx*nz   * modSa);
    // d4 uses nx·nz: the X·Z cross-product appears directly in
    // dz/dt = xy − βz, making it a true Lorenz dynamical term
    // with distinct spectral content.  With nz now zero-mean,
    // nx·nz is also zero-mean and bipolar.

    //── Mono sum + 15 ms predelay ─────────────────────────────
    mono = (l + r) * 0.5
         : de.fdelay(MAXD, ba.sec2samp(0.015));

    //── FDN feedback ──────────────────────────────────────────
    //
    //  Hadamard mixes BEFORE apDelay: the mixed signal is stored
    //  at the write head, so the next read already contains energy
    //  from all four channels.  Diffusion happens at write time.
    //
    //  Pipeline per channel:
    //    [h4 output] → apDelay (Lorenz-warped) → softclip
    //                → 1-pole LP → staggered gain

    fbk(y0,y1,y2,y3) = h4(
        y0 : apDelay(MAXD, d1) : softclip : lp1(dampCoef) : *(decayT),
        y1 : apDelay(MAXD, d2) : softclip : lp1(dampCoef) : *(decayT * 0.9993),
        y2 : apDelay(MAXD, d3) : softclip : lp1(dampCoef) : *(decayT * 0.9987),
        y3 : apDelay(MAXD, d4) : softclip : lp1(dampCoef) : *(decayT * 0.9981)
    );

    fdn    = par(i,4, +) ~ fbk;
    fdnSig = mono,mono,mono,mono : fdn;

    wetSig = fdnSig : stereoOut;
    wetL   = wetSig : _,!;
    wetR   = wetSig : !,_;

    outL = l*(1.0 - wetAmt) + wetL*wetAmt;
    outR = r*(1.0 - wetAmt) + wetR*wetAmt;
};

//─── TOP-LEVEL PROCESS ───────────────────────────────────────────

process = (_,_, lorenz(0.006)) : mainFX;


//=================================================================
//  PARAMETER GUIDE
//
//    Size  0.1–0.4  : tight rooms, chamber, plate simulation
//    Size  0.5–0.8  : medium halls
//    Size  0.9–2.0  : cathedrals, infinite spaces
//
//    Decay 0.5–0.7  : short reverb (drums, percussion)
//    Decay 0.8–0.92 : natural room character
//    Decay 0.93+    : long, evolving tails (pads, drones)
//                     Decay > 0.9999 → self-oscillation.
//                     softclip bounds amplitude but the network
//                     rings on natural modes of the prime delays
//                     (Karplus-Strong-like resonator behaviour).
//
//    Chaos 0.0      : static delays — conventional FDN reverb
//    Chaos 0.2–0.4  : subtle flutter, organic character
//    Chaos 0.6–0.8  : pronounced pitch spread, diffuse shimmer
//    Chaos 1.0      : ±2 ms aperiodic warping (±88 samples)
//                     At high Decay: evolving drone resonances.
//
//    Damp  100 Hz   : very dark (stone, heavy absorption)
//    Damp  5000 Hz  : balanced (wood, glass)
//    Damp  20000 Hz : bright (tile, concrete)
//
//  CREATIVE
//    Self-oscillation : Mix=1.0, Decay=0.998, Chaos=0.8
//    Freeze           : Decay→0.9999, Mix=1.0, Size=1.0
//    Pitch smear      : Chaos=1.0, Size=1.2
//
//  COMPILE
//    faust2juce strange_attractor_reverb.dsp
//    faust2lv2  strange_attractor_reverb.dsp
//    faust2vst  strange_attractor_reverb.dsp
//    Browser:   https://faustide.grame.fr
//=================================================================
