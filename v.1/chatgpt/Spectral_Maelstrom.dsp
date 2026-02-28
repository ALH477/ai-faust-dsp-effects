import("stdfaust.lib");

declare name "Spectral Maelstrom";
declare author "ChatGPT";
declare version "1.1";

// ================= UI =================
drive    = hslider("Drive", 1.5, 0.5, 5, 0.01);
warp     = hslider("Warp", 0.5, 0, 1, 0.001);
chaosAmt = hslider("Chaos", 0.3, 0, 1, 0.001);
feedback = hslider("Feedback", 0.3, 0, 0.95, 0.001);
mix      = hslider("Dry/Wet", 0.7, 0, 1, 0.001);

// ================= Helpers =================
wavewarp(x) = ma.tanh(drive*x + warp*x*x*x);
adaptiveSat(x) = ma.tanh(x * (1 - 0.3*abs(x)));
clip(x) = max(-1.0, min(1.0, x));

// ================= Multiband =================
low(x)  = fi.lowpass(4, 300, x);
mid(x)  = fi.bandpass(4, 1200, 1, x);
high(x) = fi.highpass(4, 4000, x);

bandProcess(x) = adaptiveSat(wavewarp(x));

multi(x) = bandProcess(low(x))
         + bandProcess(mid(x))
         + bandProcess(high(x));

// ================= Chaos =================
chaos = +(1) ~ (*(3.8 * chaosAmt)) : min(1.0) : max(-1.0);

// ================= Safe Feedback Delay =================
safeFeedback = min(feedback, 0.3); 

// map chaos [-1,1] → [8000, 12000] delay samples
safeDelay = 8000 + ((chaos + 1)/2) * 4000;

delayLine(x) = de.delay(48000, safeDelay, x * 0.5) * safeFeedback;

// ================= Mono Engine =================
monoEngine(x) = clip(x + clip(delayLine(multi(x))));

// ================= Stereo =================
process(inL, inR) =
(
    inL*(1-mix) + monoEngine((inL+inR)*0.5)*mix,
    inR*(1-mix) + monoEngine((inL+inR)*0.5)*mix
);
