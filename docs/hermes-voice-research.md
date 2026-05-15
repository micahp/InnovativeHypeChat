# Hermes Voice — On-Device AI Voice Assistant: Research Report

**Date:** 2026-05-14
**Task:** t_a476b4f2 — W3: Hermes Voice
**Goal:** Build a fully local, on-device AI voice assistant (React Native mobile app)

---

## Executive Summary

Building a fully on-device voice assistant that matches cloud quality is now feasible in 2026. The key insight: **Sherpa-ONNX serves as a unified bridge** for TTS + STT + VAD + keyword spotting via ONNX runtime, dramatically simplifying the native module surface. Combined with llama.cpp for the LLM and a lightweight TTS model (Kokoro-82M or Piper), all five components can run on-device with sub-second latency.

**Recommended stack:**
| Component | Library | Model | License |
|-----------|---------|-------|---------|
| LLM | llama.cpp | Gemma 3 4B (Q4_K_M) or Llama 3.2 1B | Apache 2.0 / Llama Community |
| STT | whisper.cpp or Sherpa-ONNX | whisper-small.en (Q5_1) | MIT |
| TTS | Sherpa-ONNX + Kokoro | Kokoro-82M (ONNX) | Apache 2.0 |
| Wake Word | Sherpa-ONNX KWS or OpenWakeWord | Custom model | Apache 2.0 / MIT |
| Bridge | React Native Turbo Modules | C++ → JSI | — |

---

## 1. TTS: Open-Source Models vs. ElevenLabs Quality

### The Challenge

ElevenLabs delivers production-grade quality: natural prosody, voice cloning, emotional range, sub-500ms latency. Open-source models are closing the gap rapidly but trade-offs exist.

### Model Rankings (Mobile Feasibility)

#### Tier 1: Mobile-Ready (Run on-device today)

| Model | Params | Quality vs ElevenLabs | Latency (mobile) | License | Notes |
|-------|--------|----------------------|------------------|---------|-------|
| **Kokoro-82M** | 82M | 7/10 — natural but less expressive | ~200ms | Apache 2.0 | Best quality-to-size ratio. 9.8M HF downloads. ONNX exportable. Clear winner for mobile. |
| **Piper** | ~50M per voice | 5/10 — intelligible, flat prosody | ~100ms | MIT | Designed for RPi/embedded. 100+ voices. Integrated into Sherpa-ONNX. Battle-tested. |
| **MeloTTS** | ~100M | 6/10 — good Mandarin/English, flat otherwise | ~300ms | MIT | Multi-lingual (EN, ES, FR, CN, JP, KR). Lightweight. ONNX export available. |

#### Tier 2: Desktop-Quality, Possible Mobile with Optimization

| Model | Params | Quality vs ElevenLabs | Latency (desktop) | License | Notes |
|-------|--------|----------------------|-------------------|---------|-------|
| **CosyVoice 2** | ~300M | 8/10 — excellent prosody, voice cloning | ~1s | Apache 2.0 | 21K GitHub stars. Flow-matching. Best open-source quality period. ONNX export WIP. |
| **ChatTTS** | ~300M | 7/10 — natural dialogue, good prosody | ~500ms | AGPL-3.0 | 39K stars. AGPL kills commercial use without negotiation. |
| **F5-TTS** | ~300M | 7/10 — flow matching, faithful reproduction | ~1s | MIT | 14.5K stars. MIT license. Good for voice cloning. |
| **Fish-Speech** | ~400M | 8/10 — SOTA quality claims | ~1.5s | Apache 2.0 (code) / CC-BY-NC-SA (model) | 30K stars. Model license restricts commercial use. |
| **XTTS v2 (Coqui)** | ~500M | 7/10 — good voice cloning, 16 languages | ~2s | MPL-2.0 (code) / Non-commercial (model) | 45K stars. Coqui is defunct. Model license problematic. |

#### Tier 3: Not Viable for Mobile

| Model | Why Not |
|-------|---------|
| **Bark** | 1.3B params, transformer-based. 10-30s generation time. Beautiful output but unusably slow on mobile. |
| **OpenVoice V2** | Voice cloning only (needs reference audio), no standalone TTS. Useful as a component. |

### Verdict

**Kokoro-82M is the clear winner for mobile TTS.** It's 82M parameters (fits in ~150MB RAM), Apache 2.0 licensed, has 9.8M+ HF downloads, and produces natural-sounding speech. For a production app, pair Kokoro with Piper as a fallback for languages Kokoro doesn't support well. CosyVoice 2 is the aspirational target once ONNX export matures.

**Gap analysis:** No open-source model matches ElevenLabs' full emotional range and ultra-low latency simultaneously. Kokoro + fine-tuning on a target voice gets you ~70% there. The remaining gap is in prosody control and emotional expressiveness.

---

## 2. STT: whisper.cpp

### Why whisper.cpp

- **38K+ GitHub stars**, MIT license
- **First-class iOS and Android support** — explicit example projects in the repo (`examples/whisper.objc`, `examples/whisper.android`)
- **Apple Silicon optimized:** ARM NEON, Accelerate, Metal, Core ML
- **Android optimized:** ARM NEON, Vulkan GPU support
- **Quantization:** Q5_1, Q4_0, etc. — tiny.en model runs real-time on iPhone 13+
- **VAD built-in:** Voice Activity Detection for continuous listening
- **Zero runtime allocations** — designed for embedded
- **C API** — trivial to bridge to React Native via JSI

### Recommended Model

| Model | Size | RAM | Speed (iPhone 15) | Accuracy |
|-------|------|-----|-------------------|----------|
| whisper-tiny.en | 75MB | ~150MB | < 100ms / second of audio | Decent for clean speech |
| whisper-small.en | 466MB | ~600MB | ~300ms / second of audio | Good — production quality |
| whisper-base.en | 142MB | ~250MB | ~150ms / second of audio | Good balance |

**Recommendation:** `whisper-small.en` for English-only, quantized to Q5_1 (~200MB). If multi-language support is needed, `whisper-small` (multilingual) at Q5_1.

### Alternative: Sherpa-ONNX

Sherpa-ONNX provides a unified ONNX runtime that includes:
- Whisper models via ONNX
- Zipformer / Paraformer models (often faster than Whisper on ARM)
- Built-in VAD
- Built-in speaker diarization
- Built-in keyword spotting

Using Sherpa-ONNX for both STT and TTS reduces the native module surface area significantly.

---

## 3. LLM: Gemma 4 Reality Check

### Gemma 4 Status (May 2026)

**Gemma 4 exists** — `google/gemma-4-31B-it` launched with 2.6K likes, 9.8M downloads on HuggingFace. However:

- **31B parameters** — requires ~20GB RAM at Q4_K_M quantization. Will not run on current mobile devices (flagship phones have 8-16GB RAM, and the OS consumes 2-4GB).
- **There is no Gemma 4 small variant** (no 1B, 2B, or 4B version) as of this writing.

### Realistic Mobile LLM Options

| Model | Params | Q4_K_M Size | Mobile RAM Req | Quality | License |
|-------|--------|-------------|----------------|---------|---------|
| **Llama 3.2 1B** | 1B | ~700MB | ~1.2GB | 3/10 — basic, fast | Llama Community |
| **Gemma 3 1B** | 1B | ~700MB | ~1.2GB | 3/10 — basic, fast | Apache 2.0 |
| **Gemma 2 2B** | 2B | ~1.3GB | ~2GB | 5/10 — decent for simple tasks | Apache 2.0 |
| **Gemma 3 4B** | 4B | ~2.5GB | ~3.5GB | 7/10 — good quality, best mobile option | Apache 2.0 |
| **Phi-3.5-mini** | 3.8B | ~2.3GB | ~3.2GB | 7/10 — strong reasoning | MIT |
| **Qwen 2.5 1.5B** | 1.5B | ~1GB | ~1.5GB | 5/10 — good for size | Apache 2.0 |

### Recommendation

**Primary: Gemma 3 4B at Q4_K_M quantization** — the best quality model that fits in mobile RAM. Requires device with 6GB+ free RAM (flagship phones from 2023+).

**Fallback: Llama 3.2 1B at Q4_K_M** — runs on virtually any modern phone, sub-1GB RAM usage. Fast enough for real-time conversation (~10-20 tok/s on iPhone 15).

**Future: Gemma 4 1B/4B** — when Google releases the small variants. Given the 31B release pattern, expect them within 2-4 months.

### llama.cpp Mobile Support

llama.cpp has:
- `examples/llama.android/` — full Android example with Kotlin/JNI
- iOS/Objective-C examples
- Swift package available
- ggml Metal backend for Apple Silicon GPU acceleration
- ARM NEON optimization for Android

---

## 4. Wake Word Detection

### Options

| Library | Quality | Latency | CPU Usage | License | Notes |
|---------|---------|---------|-----------|---------|-------|
| **OpenWakeWord** | 8/10 | <50ms | <5% on mobile | Apache 2.0 | 2.2K stars. Built for Home Assistant. ONNX-based. Custom wake words via training. |
| **Porcupine (Picovoice)** | 9/10 | <30ms | <3% on mobile | Non-commercial free / Paid | 4.8K stars. Production-grade. Custom wake words via Picovoice Console. Licensing is restrictive. |
| **Sherpa-ONNX KWS** | 7/10 | <30ms | <3% on mobile | Apache 2.0 | Built into Sherpa. Fewer pre-trained wake words. Train your own. |
| **Snowboy** | 6/10 | N/A | N/A | Discontinued | Kitt.ai acquired by Baidu, project dead. Do not use. |

### Recommendation

**OpenWakeWord** — fully open-source, Apache 2.0, ONNX-based (same runtime as our TTS/STT stack if using Sherpa-ONNX). Train custom wake words ("Hey Hermes", "Hermes", etc.) with their training pipeline. If quality is insufficient, Porcupine's free tier is a backup.

---

## 5. Architecture: React Native Native Modules

### The Bridging Challenge

All components (whisper.cpp, llama.cpp, Kokoro, OpenWakeWord) are C/C++ libraries. React Native needs native modules to bridge them.

### Strategy: Turbo Modules + JSI

```
┌─────────────────────────────────────────────┐
│              React Native (JS)               │
│  VoiceAssistant.tsx                          │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
│  │ useSTT() │ │ useLLM() │ │ useTTS()    │  │
│  └────┬─────┘ └────┬─────┘ └──────┬──────┘  │
│       │             │              │         │
│  ┌────▼─────────────▼──────────────▼──────┐  │
│  │        JSI Bridge (C++)                │  │
│  │  VoiceAssistantNativeModule           │  │
│  └────┬─────────────┬──────────────┬──────┘  │
│       │             │              │         │
│  ┌────▼────┐ ┌──────▼──────┐ ┌────▼──────┐  │
│  │llama.cpp│ │whisper.cpp  │ │Sherpa-ONNX│  │
│  │(LLM)    │ │(STT)        │ │(TTS+VAD)  │  │
│  └─────────┘ └─────────────┘ └───────────┘  │
│                      ┌──────────────┐        │
│                      │OpenWakeWord  │        │
│                      │(Wake Word)   │        │
│                      └──────────────┘        │
└─────────────────────────────────────────────┘
```

### Simplification: Sherpa-ONNX as Unified Runtime

Sherpa-ONNX (12.2K stars, Apache 2.0) can handle **TTS + STT + VAD + Keyword Spotting** through a single ONNX runtime. This means:
- **One C++ library** to bridge instead of three
- **One ONNX runtime** in memory instead of multiple inference engines
- Built-in streaming, VAD, and endpoint detection
- Android/iOS examples already in the repo

The only separate C++ library needed is llama.cpp for the LLM.

### Existing React Native Packages

| Package | Covers | Status |
|---------|--------|--------|
| `react-native-whisper` | whisper.cpp | Community, may need updates |
| `react-native-llama` | llama.cpp | Community, ~700 stars |
| `react-native-porcupine` | Porcupine wake word | Official Picovoice |

**Recommendation:** Build a single custom Turbo Module (`react-native-hermes-voice`) that bundles:
1. llama.cpp (LLM)
2. Sherpa-ONNX (TTS + STT + VAD + KWS)

This gives us two C++ dependencies instead of four, and Sherpa-ONNX's unified API simplifies the JSI bridge significantly.

---

## 6. Starting Point: Existing Repos

### InnovativeHypeChat (micahp/InnovativeHypeChat)

- **What it is:** Customized LibreChat fork — a web-based ChatGPT clone with Ollama RAG, OpenRouter integration
- **Stack:** Node.js/Express backend, React frontend, MongoDB, Docker
- **Relevance to this task:** LOW. It's a web app, not mobile. The RAG/chat patterns could inspire the conversation management, but the architecture is entirely different.
- **Reusable pieces:** The conversation management logic, prompt templates, and media handling patterns could be ported to React Native.

### local-llm-studio (micahp/local-llm-studio)

- **Status:** Does not exist on GitHub yet (404). Referenced in task as "newly built."
- **Presumed content:** A local LLM studio app — possibly the Next.js 14 app from t_0673b3d4 ("Clone AI Edge Studio — local LLMs with conversation saving and media").
- **Relevance:** If it exists locally, its conversation management, llama.cpp integration, and media handling could be adapted.

### Recommendation

DO NOT fork or extend InnovativeHypeChat for this task. It's a web app with a fundamentally different architecture. Instead, start fresh with a React Native (Expo) project and build the native module layer from scratch. Borrow only the conversation schema and prompt patterns from IHC.

---

## 7. Continuous Conversation Mode

### Architecture

```
┌──────────────────────────────────────────────────┐
│                 Conversation Loop                  │
│                                                    │
│  [Wake Word] → [STT] → [LLM] → [TTS] → [Listen]  │
│       ↑                                      │     │
│       └──────────── (loop back) ─────────────┘     │
│                                                    │
│  States:                                           │
│  IDLE → LISTENING → PROCESSING → SPEAKING → IDLE  │
│                                                    │
│  Interruption handling:                            │
│  - User can interrupt TTS with wake word           │
│  - VAD detects end of speech automatically         │
│  - Barge-in: if user starts talking during TTS,    │
│    fade out TTS and switch to LISTENING            │
└──────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **VAD-based turn detection** — whisper.cpp and Sherpa-ONNX both have VAD. Use it to detect when the user stops speaking instead of requiring a button press.

2. **Barge-in support** — Play TTS audio through the phone's media channel. Monitor the mic during playback. If speech energy exceeds threshold for >300ms, fade out TTS and switch to listening.

3. **Wake word vs. always-listening** — Use wake word to initiate, VAD for turn boundaries within a conversation, and a timeout (e.g., 30 seconds of silence) to return to wake-word-only mode.

4. **Streaming TTS** — Kokoro-82M generates audio in <200ms. For longer responses, stream tokens through the LLM and generate TTS chunks incrementally. This gives the illusion of real-time conversation.

---

## 8. Device Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 4GB free | 6GB+ free |
| Storage | 3GB for models | 5GB for all components |
| CPU | ARMv8 (2018+) | Apple A15 / Snapdragon 8 Gen 2+ |
| GPU | Not required | Metal / Vulkan for acceleration |
| OS | iOS 16+ / Android 13+ | Latest |

**Realistic target devices:** iPhone 13+, Pixel 7+, Galaxy S22+, any flagship from 2022+.

---

## 9. Model Download & Management

### Strategy

Bundle nothing — download models on first launch:

1. App ships with a model manifest (URLs, checksums, sizes)
2. On first launch, user chooses which models to download
3. Download with progress, resume support
4. Verify SHA256 after download
5. Store in app's documents directory

### Hosting

Models can be hosted on:
- HuggingFace (free, rate-limited)
- GitHub Releases (free, 2GB limit per file)
- S3/CloudFront (cheap, fast)

For an MVP, HuggingFace direct downloads work fine.

---

## 10. Development Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] React Native (Expo) project setup
- [ ] Native module scaffold (Turbo Modules + JSI)
- [ ] llama.cpp integration — load GGUF, streaming inference
- [ ] Basic chat UI (text-in, text-out)

### Phase 2: Voice I/O (Week 3-4)
- [ ] Sherpa-ONNX integration (or whisper.cpp direct)
- [ ] STT: mic → text, with VAD
- [ ] TTS: text → audio output, Kokoro-82M
- [ ] Wake word detection

### Phase 3: Conversation (Week 5-6)
- [ ] Continuous conversation loop
- [ ] Barge-in / interruption
- [ ] Streaming TTS
- [ ] Conversation history & persistence

### Phase 4: Polish (Week 7-8)
- [ ] Voice personality / system prompt engineering
- [ ] Multi-voice support
- [ ] Performance optimization
- [ ] Model management UI
- [ ] App store submission prep

---

## 11. Key Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gemma 4 too large for mobile | High | Use Gemma 3 4B or Llama 3.2 1B. Monitor for Gemma 4 small release. |
| Kokoro quality not good enough | Medium | Fallback to CosyVoice 2 when ONNX export matures. Piper as emergency backup. |
| Battery drain from continuous mic | Medium | Use hardware wake word (DSP) where available. Aggressive VAD to minimize processing. |
| React Native JSI complexity | Medium | Use Sherpa-ONNX to minimize native surface. Study whisper.cpp ObjC example for patterns. |
| App Store rejection | Low | Both Apple and Google allow on-device ML. No network permission needed. |

---

## 12. References

- **llama.cpp**: https://github.com/ggml-org/llama.cpp (110K stars, MIT)
- **whisper.cpp**: https://github.com/ggml-org/whisper.cpp (38K stars, MIT)
- **Sherpa-ONNX**: https://github.com/k2-fsa/sherpa-onnx (12K stars, Apache 2.0)
- **Kokoro-82M**: https://huggingface.co/hexgrad/Kokoro-82M (Apache 2.0)
- **OpenWakeWord**: https://github.com/dscripka/openWakeWord (2.2K stars, Apache 2.0)
- **Gemma 3**: https://huggingface.co/google/gemma-3-4b-it
- **Gemma 4**: https://huggingface.co/google/gemma-4-31B-it
- **Coqui TTS / XTTS v2**: https://github.com/coqui-ai/TTS (45K stars)
- **ChatTTS**: https://github.com/2noise/ChatTTS (39K stars)
- **CosyVoice**: https://github.com/FunAudioLLM/CosyVoice (21K stars)
- **Fish-Speech**: https://github.com/fishaudio/fish-speech (30K stars)
- **Piper**: https://github.com/rhasspy/piper (11K stars, MIT)
- **MeloTTS**: https://github.com/myshell-ai/MeloTTS (7.4K stars, MIT)
