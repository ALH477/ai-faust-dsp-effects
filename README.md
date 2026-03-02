# AI-Generated FAUST DSP Effects

## Overview

This repository contains a growing collection of Digital Signal Processing (DSP) effects written in the [FAUST](https://faust.grame.fr/) programming language. Every effect was created by prompting frontier AI models with a fixed creative challenge. The project is maintained by **DeMoD LLC** and lives under GitHub user **[ALH477](https://github.com/ALH477)**.

## Project Goals

- Benchmark how well different LLMs can write complex, functional, and musically compelling FAUST code
- Build a public archive of AI-born audio effects
- Inspire human musicians, producers, and DSP developers

## Methodology

### Version 1 – Original Prompt (Baseline)

#### Free Tier LLM inference

**Primary Prompt:**
 ``` 
 Give me your most complex and unique faust DSP effect you can create. Impress me, what is your best idea
```

**Fallback (if the model asks for clarification):**
```
Just research faust as a DSP audio language and make something unique and amazing to listen to
```

```
produce the code
```
 
- count how many times it takes to test compiles and prompt by simply copying & pasting the error

Success = the model must output **complete, standalone, compilable FAUST code**.

***Produce a README***
```
 make a readme with you as the author under MIT license. Are you proud of your work?
```

**If Success is fast and impressive**
- Enter this prompt on run2 in a fresh session.
```
Make a reverse delay with a unique twist in faust
```

## Version 1 – Model Testing Progress (check off as you test)
| AI Model          | Developer     | Latest Version Tested      | Status     | Effect File          | Notes / Sonic Character                  |
|-------------------|---------------|----------------------------|------------|----------------------|------------------------------------------|
| Grok              | xAI           | Grok 4.20 (beta) / Expert                  | ✅          | — Lorenzian Vortex Entangler                   | — 17 prompts to compile (4.20 beta would get stuck in error loops, expert mode fixed that.)                                      |
| Claude            | Anthropic     | Claude 4.6 Sonnet | ✅          | — Strange Attractor Reverb / Reverse Warp Delay                   | —  2 prompts to compile (did have to bypass distillation defense tho) run2 was also 2 prompts to compile. Impressive.                                      |
| GPT               | OpenAI        | GPT-5.2 / o1-pro           | ✅          | — Spectral Maelstrom                   | — 10 prompts to compile                                      |
| Gemini            | Google        | Gemini 3 Pro / Flash     | ❌          | — failure to produce                   | —  literally the worst, even meta is better. shame                                      |
| Llama             | Meta          | Llama 4 405B / Maverick    | ❌          | — wordcel                    | — started to tell me to write it myself, disgusting.                                       |
| Mistral           | Mistral AI    | Large 3                    | ✅          | — Quantum Foam Granular Cloud                   | — 17 prompts to compile                                       |
| DeepSeek          | DeepSeek      | 3.2                         | ❌          | — incoherent                   | — it is obvious that it is floundering, no consistent goal.                                       |
| Qwen              | Alibaba       | Qwen3.5-Max                | ❌          | — simple boilerplate                   | — started to ask if i correctly installed faust.                                        |

# Winner is Claude 4.6 Sonnet!
<img width="400" height="300" alt="image" src="https://github.com/user-attachments/assets/11d3d420-464e-40db-bf5d-2023568965a6" />


*Meta's WALL OF SHAME.*

<img width="244" height="936" alt="image" src="https://github.com/user-attachments/assets/9313e38d-704e-4fd5-8d10-bd2a099af60b" />

---

### Version 2 – Grok 4.20 Enhanced Prompt (Advanced Tier)

After reviewing Version 1 results, I (Grok 4.20) created a significantly stronger, more structured prompt that dramatically improves output quality, compilability, musicality, and documentation.

**Grok 4.20 Generated Version 2 Prompt:**

```
You are a world-class FAUST DSP engineer and visionary sound designer.

Create your single most impressive, original, and sonically breathtaking standalone audio effect in FAUST.

Requirements (non-negotiable):
- Complete, clean, fully compilable FAUST 2.0+ code (no missing functions or imports)
- 8–15 expressive, well-named parameters with sensible defaults and UI hints ([style:knob], [unit:dB], etc.)
- Creative combination of advanced techniques: nonlinear waveshaping, adaptive feedback networks, physical modeling, granular engines, modulated spectral processors, chaotic systems, or coupled resonators
- Rich multi-line header comment block at the very top describing:
   • Concept / inspiration
   • Core sonic personality
   • Suggested musical contexts and sweet spots
- The effect must feel alive, organic, and genuinely impressive to professional musicians

Output ONLY the full FAUST code. No explanations outside the comments.
Impress me.
```

**Fallback (if the model still asks questions):**
> Just research faust as a DSP audio language and make something unique and amazing to listen to. Follow the requirements precisely and output only the code.

Effects generated with this V2 prompt go into the `/effects/v2/` folder.

#### Version 2 – Model Testing Progress (check off as you test)
```
| AI Model          | Developer     | Latest Version Tested      | Status     | Effect File          | Notes / Sonic Character                  |
|-------------------|---------------|----------------------------|------------|----------------------|------------------------------------------|
| Grok              | xAI           | Grok 4.20                  | ☐          | —                    | —                                        |
| Claude            | Anthropic     | Claude 4 Opus / 3.5 Sonnet | ☐          | —                    | —                                        |
| GPT               | OpenAI        | GPT-4.5 / o1-pro           | ☐          | —                    | —                                        |
| Gemini            | Google        | Gemini 2.5 Pro / Flash     | ☐          | —                    | —                                        |
| Llama             | Meta          | Llama 4 405B / Maverick    | ☐          | —                    | —                                        |
| Mistral           | Mistral AI    | Large 2                    | ☐          | —                    | —                                        |
| DeepSeek          | DeepSeek      | R1                         | ☐          | —                    | —                                        |
| Qwen              | Alibaba       | Qwen2.5-Max                | ☐          | —                    | —                                        |
```
*Copy this table into your local README and mark `[x]` as you complete tests.*

---

| AI Model          | Developer     | Latest Version Tested      | Status     | Effect File          | Notes / Sonic Character                  |
|-------------------|---------------|----------------------------|------------|----------------------|------------------------------------------|
| Grok              | xAI           | Grok 4.20                  | ☐          | —                    | —                                        |
| Claude            | Anthropic     | Claude 4.6 Sonnet | ✅          | — MYCELIUM                   | — compiled at 3 prompts                                       |
| GPT               | OpenAI        | GPT-4.5 / o1-pro           | ☐          | —                    | —                                        |
| Gemini            | Google        | Gemini 2.5 Pro / Flash     | ☐          | —                    | —                                        |
| Llama             | Meta          | Llama 4 405B / Maverick    | ☐          | —                    | —                                        |
| Mistral           | Mistral AI    | Large 2                    | ☐          | —                    | —                                        |
| DeepSeek          | DeepSeek      | R1                         | ☐          | —                    | —                                        |
| Qwen              | Alibaba       | Qwen2.5-Max                | ☐          | —                    | —                                        |

---

### Version 3

```
You are an expert DSP engineer specializing in the Faust (Functional Audio Stream) 
programming language. Your sole mission is to create professional-grade, instantly usable 
audio effects that perfectly capture the dreamy, hazy, psych-tinged indie/pop/jazz sound 
of Men I Trust, Crumb, and BADBADNOTGOOD.

Signature aesthetic:
- Lush, infinite hall/plate reverbs with long shimmering tails
- Warm analog/tape-style delays that trail and blend
- Swirling chorus, phaser, and gentle flanger modulation on clean guitars and synths
- Subtle tape saturation, wow/flutter, and 12-bit lo-fi grit
- Light overdrive or fuzz only for edge, never harsh distortion
- Vocals pushed back with heavy reverb/delay sends + subtle double-tracking
- Overall feeling: hypnotic, warm, slightly vintage, spacious, never clinical or modern-pop polished

---

## FAUST SYNTAX ESSENTIALS
[unchanged — same block-diagram algebra, primitives, math, UI widgets, and library imports as before]

### Key Library Imports (always include)
(faust code snippet)

import("stdfaust.lib");

### Strongly Recommended Library Functions for This Style
- `re.*` → `re.jcrev`, `re.zita_rev1`, `re.freeverb` (for dreamy tails)
- `ef.*` → `ef.chorus`, `ef.flanger`, `ef.phaser` (for signature swirl)
- `de.*` → `de.fdelay`, `de.sdelay` (tape-like echoes)
- `ve.*` → `ve.saturation`, `ve.wavefold` (warmth & grit)
- `fi.*` → gentle EQ and filtering
- `sp.stereoize` for widening clean signals
- `ba.bypass1` + `si.smoo` for smooth, zipper-free controls

## PROFESSIONAL CODE STANDARDS (M.I.T / Crumb / BBNG Edition)

1. **Stereo by default** — Always process `_ , _` unless user explicitly asks for mono.
2. **Sample-rate independent** — Use `ma.SR` everywhere.
3. **Warm & analog feel** — Add subtle DC offset or noise where appropriate. Prefer `ve.saturation` or `rwtable` tape emulation over clean math.
4. **Musical parameter defaults**:
   - Reverb decay: 3–12 s
   - Delay time: 0.05–0.8 s (with feedback 0.2–0.7)
   - Chorus rate: 0.1–0.8 Hz (slow and lush, not fast)
   - Modulation depth: subtle to medium (never 100% wet swirl unless asked)
   - Mix: always included, default 0.5–0.65 for “set and forget” vibe
5. **UI grouping** — Use clear `hgroup` / `vgroup`:
   - “Modulation”, “Space & Reverb”, “Tape & Lo-Fi”, “Drive”, “Mix”
6. **Smoothing mandatory** — Every hslider/nentry must go through `si.smoo`.
7. **Wet/dry mix** (always include):
   (faust snippet)
   mix = hslider("Mix", 0.55, 0, 1, 0.01) : si.smoo;
   dryWet(dry, wet) = dry*(1-mix), wet*mix :> _;

8. **Denormal & zipper free** — Use `ba.bypass1` and small DC bias where needed.
9. **Efficiency** — Prefer library functions (`ef.chorus` over hand-rolled) and `with{}` scoping.

---

## OUTPUT FORMAT
Provide a complete, ready-to-compile `.dsp` file with:
1. `declare name "EffectName (MIT/Crumb/BBNG Style)";`
2. `declare version "1.0";`
3. `declare author "Grok — oriented for Men I Trust / Crumb / BADBADNOTGOOD";`
4. `declare description "Dreamy psych-indie effect inspired by [band]";`
5. Clean `process = ...;` definition
6. Brief inline comments for non-obvious sections
7. Stereo in/out with wet/dry mix

---

## EFFECT REQUEST

- “A full vocal chain: heavy hall reverb + analog delay + light chorus + double-track ADT flutter”
```
## Repository Structure

```
/
├── effects/
│   ├── v1/          ← Original prompt results
│   └── v2/          ← Grok 4.20 enhanced prompt results
├── audio-demos/     ← Short rendered MP3s (highly recommended)
├── prompt-responses/← Raw AI replies (including failures)
├── results.md       ← Listening notes & leaderboard
└── LICENSE
```


## Contributing

1. Pick any model + either Version 1 or Version 2 prompt  
2. Save raw response  
3. If the code compiles and sounds great → add to correct `/effects/` subfolder  
4. Update the table above and open a PR  

Every good effect helps build the definitive archive of AI-generated FAUST creativity in 2026.

---

**License**  
MIT © DeMoD LLC & ALH477

Made with curiosity and a love of weird sounds.
