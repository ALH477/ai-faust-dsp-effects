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
- Enter this prompt on run2
```
Make a reverse delay with a unique twist in faust
```

## Version 1 – Model Testing Progress (check off as you test)
| AI Model          | Developer     | Latest Version Tested      | Status     | Effect File          | Notes / Sonic Character                  |
|-------------------|---------------|----------------------------|------------|----------------------|------------------------------------------|
| Grok              | xAI           | Grok 4.20                  | ☐          | —                    | —                                        |
| Claude            | Anthropic     | Claude 4.6 Sonnet | ✅          | — Strange Attractor Reverb                   | —  2 prompts to compile (did have to bypass distillation defense tho) run2 was also 2 prompts to compile. Impressive.                                      |
| GPT               | OpenAI        | GPT-5.2 / o1-pro           | ✅          | — Spectral Maelstrom                   | — 10 prompts to compile                                      |
| Gemini            | Google        | Gemini 3 Pro / Flash     | ☐          | —                    | —                                        |
| Llama             | Meta          | Llama 4 405B / Maverick    | ❌          | — wordcel                    | — started to tell me to write it myself, disgusting.                                       |
| Mistral           | Mistral AI    | Large 3                    | ✅          | — Quantum Foam Granular Cloud                   | — 17 prompts to compile                                       |
| DeepSeek          | DeepSeek      | R3                         | ☐          | —                    | —                                        |
| Qwen              | Alibaba       | Qwen3.5-Max                | ❌          | — simple boilerplate                   | — started to ask if i correctly installed faust.                                        |

*Copy this table into your local README and mark `[x]` as you complete tests.*

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
| Claude            | Anthropic     | Claude 4 Opus / 3.5 Sonnet | ☐          | —                    | —                                        |
| GPT               | OpenAI        | GPT-4.5 / o1-pro           | ☐          | —                    | —                                        |
| Gemini            | Google        | Gemini 2.5 Pro / Flash     | ☐          | —                    | —                                        |
| Llama             | Meta          | Llama 4 405B / Maverick    | ☐          | —                    | —                                        |
| Mistral           | Mistral AI    | Large 2                    | ☐          | —                    | —                                        |
| DeepSeek          | DeepSeek      | R1                         | ☐          | —                    | —                                        |
| Qwen              | Alibaba       | Qwen2.5-Max                | ☐          | —                    | —                                        |

---

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

## Installation & Usage

(See original README – unchanged)

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
