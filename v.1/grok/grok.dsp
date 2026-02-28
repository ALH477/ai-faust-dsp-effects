declare name "Grok's Lorenzian Vortex Entangler v2.5";
declare author "Grok (xAI)";
declare description "Real-time 3D Lorenz chaos modulated stereo cross-delay + Zita FDN reverb + 16-voice resonant filter bank — Nix-proof";
declare version "2.5";
declare license "MIT";

import("stdfaust.lib");
re = library("reverbs.lib");

// ==================== UI PARAMETERS ====================
dryWet      = hslider("[0] Dry/Wet [unit:%]", 50, 0, 100, 0.1) / 100 : si.smoo;
preDrive    = hslider("[1] Pre-Distortion", 1.5, 1, 5, 0.01) : si.smoo;
masterGain  = hslider("[2] Master Gain [unit:dB]", 0, -12, 12, 0.1) : ba.db2linear : si.smoo;

chaosSpeed  = hslider("[3] Chaos Speed (dt)", 0.004, 0.0005, 0.02, 0.0001) : si.smoo;
modAmount   = hslider("[4] Chaos Amount", 0.65, 0, 1, 0.01) : si.smoo;

baseDelay   = hslider("[5] Base Delay (ms)", 185, 10, 1200, 1) * 0.001 : si.smoo;
feedback    = hslider("[6] Feedback", 0.68, 0, 0.98, 0.01) : si.smoo;
crossMix    = hslider("[7] Cross-Mix", 0.42, 0, 1, 0.01) : si.smoo;

revPredelay = hslider("[8] Reverb Predelay (ms)", 18, 0, 80, 1) : si.smoo;
revT60      = hslider("[9] Reverb Decay (s)", 2.8, 0.5, 12, 0.01) : si.smoo;
resSpread   = hslider("[10] Resonance Spread", 0.75, 0, 2, 0.01) : si.smoo;
resQ        = hslider("[11] Resonance Q", 4.5, 1, 12, 0.1) : si.smoo;

// ==================== LORENZ CHAOTIC ATTRACTOR (manual impulse + integrator) ====================
sigma = 10; rho = 28; beta = 8.0/3.0;
dt = chaosSpeed;

lorenz_derivative(x, y, z) = sigma*(y - x), x*(rho - z) - y, x*y - beta*z;

// Manual impulse (1 at t=0, 0 otherwise)
impulse = 1 <: _, _' : - <: (_, 0 : >), _ : *;

// Init impulse scaled
initImpulse = impulse * 0.1;

// Integrator loop with init injection
chaos = (initImpulse, initImpulse, initImpulse) : (+, +, +) ~ (lorenz_derivative : (*(dt), *(dt), *(dt)));

chaosRawX = chaos : _,!,!;
chaosRawY = chaos : !,_,!;
chaosRawZ = chaos : !,!,_;

chaosX = chaosRawX / 19 * modAmount : si.smoo;
chaosY = chaosRawY / 19 * modAmount : si.smoo;
chaosZ = (chaosRawZ / 26 * 2 - 1) * modAmount : si.smoo;

// ==================== DELAY NETWORK ====================
MAX_DELAY_SEC = 3.0;
maxDelSamps = ba.sec2samp(MAX_DELAY_SEC);
interp = 512;

timeL = ba.sec2samp(baseDelay * (1 + chaosX*0.35)) : si.smoo;
timeR = ba.sec2samp(baseDelay * 0.72 * (1 + chaosY*0.28)) : si.smoo;

fbGain = feedback * (1 + chaosZ*0.18) : min(0.995);
cross = crossMix * (1 + chaosZ*0.25);

distDrive = preDrive * (1 + abs(chaosZ)*1.2);
icurve = 1.0 / atan(distDrive);
atandist(x) = icurve * atan(x * distDrive);

fbFilter = atandist : fi.lowpass(2, 8500 * (1 + chaosY*0.4)) : fi.highpass(2, 45 * (1 + chaosX*0.3));

delayNet(lIn, rIn) =
    (lIn, rIn) <:
    (de.sdelay(maxDelSamps, interp, timeL), de.sdelay(maxDelSamps, interp, timeR)) :
    (*(fbGain), *(fbGain)) :
    crossmix(cross) :
    (fbFilter, fbFilter)
with {
    crossmix(c) = \(l, r). (l*(1-c) + r*c, l*c + r*(1-c));
};

// ==================== ZITA REVERB ====================
zitaPath(l, r) =
    (l, r) : re.zita_rev1_stereo(
        revPredelay + chaosX*8,
        180 + chaosY*120,
        2200 + chaosZ*800,
        revT60 * (1 + chaosY*0.6),
        revT60 * 0.7 * (1 + chaosZ*0.4),
        48000
    );

// ==================== RESONANT FILTER BANK (fixed recursive parallel sum) ====================
monoResBank = bank(16) : _ / 9
with {
    bank(0) = _ * 0;
    bank(n) = _ <: bank(n-1), (fi.resonbp(120 * (2.0^((n-1)/3.8)) * (1 + chaosZ*resSpread*0.18), resQ * (1 + abs(chaosY)*0.8), 0.75)) : +;
};

resBank(l, r) = (l : monoResBank), (r : monoResBank);

// ==================== WET PATH ====================
wetPath(lIn, rIn) =
    (lIn, rIn) :
    (preClip, preClip) <:
        delayNet,
        zitaPath,
        resBank :>
    (postClip, postClip) :
    *(0.28), *(0.28)
with {
    preClip  = _ * preDrive : ma.tanh;
    postClip(x) = x / (1.0 + abs(x));  // zero-dependency soft clip
};

// ==================== FINAL PROCESS ====================
process = 
    _, _ <:
        *(1-dryWet), *(1-dryWet),
        wetPath :>
        *(masterGain), *(masterGain);
