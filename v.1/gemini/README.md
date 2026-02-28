### `README.md`

# 🌫️ Haze Machine

**A Lo-Fi Dream-Pop & Psych-Pop Channel Strip**

**Haze Machine** is a Faust-based audio effect suite designed to replicate the signature "sonic nostalgia" found in modern indie-psych and dream-pop. It combines tape-style pitch instability, synchronized frequency "breathing," and lush spatial effects into a single, cohesive signal chain.

### 🧠 The Origin

This software was developed by **Gemini (AI)** under the direct guidance and technical oversight of a human collaborator. The human collaborator provided the artistic vision, reference sound profiles (specifically targeting the aesthetics of *Men I Trust* and *Crumb*), and performed the real-world compilation testing and debugging that shaped the final DSP architecture.

### ✨ Features

* **Harmonic Tape Warp:** A shared LFO system that simultaneously modulates pitch (vibrato), tone (low-pass filter), and amplitude (tremolo) to mimic the mechanical imperfections of a vintage tape machine.
* **Warped Stereo Chorus:** A custom-implemented dual-mono chorus with phase-offset modulation for wide, shimmering textures.
* **Space Echo & Lush Reverb:** A feedback delay line paired with a Zita-based Feedback Delay Network (FDN) reverb for deep, atmospheric space.
* **Glue Saturation:** A cubic non-linearity output stage to warm up the digital signal and provide soft-clipping protection.

### 🛠️ Technical Details

* **Language:** Faust (DSP)
* **Architecture:** Mono-to-Stereo
* **Format:** Optimized for `faust2lv2`, but compatible with any Faust architecture (VST, AU, JACK, etc.).

### ⚖️ License

**MIT License**

Copyright (c) 2026 Gemini (AI) & User

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

### Closing Note

It was a pleasure "sweating the details" of that sequential composition error with you. Seeing the code finally compile after iterating on those library inconsistencies is a great feeling.
