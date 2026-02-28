import("stdfaust.lib");

// =================================================================================
// 🎛️ UI & GLOBAL CONTROLS
// =================================================================================

gMod   = vgroup(" Tape Warp (Shared LFO)", _);
gEcho  = vgroup(" Space Echo", _);
gOut   = vgroup(" Master Output", _);

// --- The "Harmonizer" (Shared LFO) ---
warpRate  = gMod(hslider("Warp Rate [style:knob]", 1.2, 0.1, 10, 0.1));
warpDepth = gMod(hslider("Warp Depth", 0.5, 0, 1, 0.01)); 

lfo = os.osc(warpRate) * 0.5 + 0.5; 

// =================================================================================
// 🎸 CUSTOM MODULES
// =================================================================================

// 1. Mono Lo-Fi Engine
inputClean = fi.highpass(2, 80);
wobble = de.fdelay(500, 10 + (lfo * warpDepth * 20));
breathFilter = fi.lowpass(2, 6000 - (lfo * warpDepth * 2000));
tapeDrop = _ * (1 - (lfo * warpDepth * 0.3));

lofiEngine = inputClean : wobble : breathFilter : tapeDrop;

// 2. Custom Chorus
myChorus(rate, depth, phaseOffset) = _ <: _, modulatedDelay : + : *(0.6)
with {
    mod = os.oscp(rate, phaseOffset) * depth * 0.005; 
    modulatedDelay = de.fdelay(0.05 * ma.SR, (0.02 + mod) * ma.SR);
};

// 3. Stereo Delay & Reverb
tapeDelayModule = + ~ (de.delay(48000, 0.3 * 48000) : *(0.4) : fi.lowpass(1, 2000));
lushReverb = re.zita_rev1_stereo(0.4, 200, 3.0, 2.0, 0.5, 48000);

// =================================================================================
// ✨ THE FIX: STEREO SATURATOR
// =================================================================================

// We define a mono saturator first...
saturator_mono = ef.cubicnl(0.1, 0) : _ * 0.8;

// ...then we apply it to both channels in parallel.
// This creates 2 inputs and 2 outputs.
saturator_stereo = (saturator_mono, saturator_mono);

// =================================================================================
// 🏁 MAIN PROCESS
// =================================================================================

process = _ 
    : lofiEngine            // Mono in, Mono out
    <:                      // Split Mono to Stereo
    (myChorus(0.5, 0.5, 0), myChorus(0.55, 0.5, ma.PI)) 
    : (tapeDelayModule, tapeDelayModule) 
    : lushReverb            // Stereo in, Stereo out
    : saturator_stereo;     // Stereo in, Stereo out
