import("stdfaust.lib");

// Define parameters
grainSize = hslider("grain_size[unit:ms]", 50, 1, 100, 1);
feedbackAmount = hslider("feedback_amount", 0.5, 0, 1, 0.01);
modulationDepth = hslider("modulation_depth", 0.5, 0, 1, 0.01);
chaosAmount = hslider("chaos_amount", 0.5, 0, 1, 0.01);
delayTime = hslider("delay_time[unit:ms]", 500, 10, 1000, 1);
distortionAmount = hslider("distortion_amount", 0.5, 0, 1, 0.01);
quantumFoam = hslider("quantum_foam", 0.5, 0, 1, 0.01);
flocking = hslider("flocking", 0.5, 0, 1, 0.01);

// Define a simple low-pass filter using a one-pole filter
lowpass = *(0.1) : + ~ *(0.9);

// Define a granular cloud engine with fixed delay time and simple low-pass filter
granularCloud(input) = input <: de.delay(100) : lowpass;

// Define feedback with modulation
feedback(input) = input * (feedbackAmount * (1 + modulationDepth * os.osc(10)));

// Define chaotic modulation using a logistic map
chaosMod(input) = input * (os.osc(1 + chaosAmount * 10) * 0.5 + 0.5);

// Define a nonlinear distortion
distortion(input) = input * (1 + distortionAmount * (input * input - 1));

// Define a string resonance model with fixed delay time
stringModel(input) = input <: de.delay(500);

// Define quantum foam modulation
quantumFoamMod(input) = input * (1 + quantumFoam * (no.noise * 0.1));

// Define a self-modulating delay network with fixed delay time
selfModulatingDelay(input) = input <: de.delay(500);

// Define a flocking algorithm for grains
flockingAlgorithm(input) = input * (os.osc(1 + flocking * 10) * 0.5 + 0.5);

// Combine everything
process = _ : granularCloud : feedback : chaosMod : distortion : stringModel : quantumFoamMod : selfModulatingDelay : flockingAlgorithm;

