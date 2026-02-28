import("stdfaust.lib");

declare name "Spectral Maelstrom Pro";
declare author "ChatGPT";
declare version "1.2";
declare license "BSD 3-Clause";

// ================= LV2 Metadata =================
// Slider ranges, units, and tooltips for DAW UI
declare drive   "unit:ratio, tooltip:Drive amount of distortion";
declare warp    "unit:ratio, tooltip:Wavewarp nonlinearity amount";
declare chaosAmt "unit:ratio, tooltip:Chaos modulation intensity";
declare feedback "unit:ratio, tooltip:Feedback amount (max 0.3 for stability)";
declare mix     "unit:ratio, tooltip:Dry/Wet mix";

// ================= UI =================
drive     = hslider("Drive", 1.5, 0.5, 5, 0.01) : si.smoo;
warp      = hslider("Warp", 0.5, 0, 1, 0.001) : si.smoo;
chaosAmt  = hslider("Chaos", 0.3, 0, 1, 0.001) : si.smoo;
feedback  = hslider("Feedback", 0.25, 0, 0.3, 0.001) : si.smoo; // capped
mix       = hslider("Dry/Wet", 0.7, 0, 1, 0.001) : si.smoo;

// ================= Helpers =================
wavewarp(x) = ma.tanh(drive*x + warp*x*x*x);
adaptiveSat(x) = ma.tanh(x * (1 - 0.3*abs(x)));
clip(x) = max(-1.0, min(1.0, x));
nonlinear(x) = clip(adaptiveSat(wavewarp(x)));

// ================= Multiband =================
low(x)  = fi.lowpass(4, 300, x);
mid(x)  = fi.bandpass(4, 1200, 1, x);
high(x) = fi.highpass(4, 4000, x);
multi(x) = nonlinear(low(x)) + nonlinear(mid(x)) + nonlinear(high(x));

// ================= Chaos =================
chaos = +(1) ~ (*(3.8 * chaosAmt)) : min(1.0) : max(-1.0);

// ================= FDN =================
maxDelay = 48000;
safeFeedback = feedback;

// Explicit 4 delay lines
d0 = de.delay(maxDelay, 10000 + ((chaos+1)/2)*2000, nonlinear(0));
d1 = de.delay(maxDelay, 12000 + ((chaos+1)/2)*2000, nonlinear(0));
d2 = de.delay(maxDelay, 14000 + ((chaos+1)/2)*2000, nonlinear(0));
d3 = de.delay(maxDelay, 16000 + ((chaos+1)/2)*2000, nonlinear(0));

// Orthogonal feedback matrix
f0 = 0.5*d0 + 0.5*d1 - 0.5*d2 + 0.5*d3;
f1 = -0.5*d0 + 0.5*d1 + 0.5*d2 + 0.5*d3;
f2 = 0.5*d0 - 0.5*d1 + 0.5*d2 + 0.5*d3;
f3 = 0.5*d0 + 0.5*d1 + 0.5*d2 - 0.5*d3;

// Apply safe feedback
fdnOut0 = clip(f0 * safeFeedback);
fdnOut1 = clip(f1 * safeFeedback);
fdnOut2 = clip(f2 * safeFeedback);
fdnOut3 = clip(f3 * safeFeedback);

// ================= Mono Engine =================
monoEngine(x) = clip(x + (fdnOut0 + fdnOut1 + fdnOut2 + fdnOut3)*0.25);

// ================= Stereo =================
process(inL, inR) =
(
    inL*(1-mix) + monoEngine((inL+inR)*0.5)*mix,
    inR*(1-mix) + monoEngine((inL+inR)*0.5)*mix
);
