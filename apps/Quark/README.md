<p align="center">
  <img src="Quark/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="104" alt="Quark" />
</p>

# Quark - Learn STEM

A playful, private way to build STEM fluency five minutes at a time. Six tracks, short sessions, and a path that sends you back to whatever is starting to fade. Apple Intelligence writes the hints, the explanations, and the occasional bonus question — **on your device, and only after every one of them has passed eleven of Quark's own checks**. With the model switched off, or on a device that does not support it, Quark is still a complete app.

## Features

- **Six STEM tracks** — Mathematics, Physics, Chemistry, Biology, Computing, and Data & Stats: 24 lessons and 120 hand-written questions that ship with the binary
- **Six question kinds** — multiple choice, true/false, numeric entry, short text, ordering a procedure, and matching pairs, interleaved rather than blocked
- **A path that decays** — mastery is not "finished once". Recall is modelled per lesson, so a node can quietly lose its crown and ask for you back
- **On-device coaching powered by Apple Intelligence** — hints that point at the method, explanations tuned to the answer you actually gave, and a short conversation about the question in front of you
- **Bonus questions written on device** — labelled as generated, and only after the full guardrail review
- **Guardrails you can read** — all eleven are listed in Settings, in one line each, with the reason each exists
- **The reward loop** — XP, combos, levels, sparks, a daily goal ring, and a streak, with sparks switchable off for learners who do worse under pressure
- **Fully offline** — no account, no network calls, no analytics. Progress is one JSON file in the app's own container
- **Built for accessibility** — VoiceOver labels on every control, tap-only ordering and matching, and Reduce Motion respected throughout

## How a session is produced

Quark is deliberately split in two. Everything below the UI — curriculum, grading, scheduling, scoring, and the entire guardrail layer — is Foundation-only and pure, which means it can be unit-tested off-device and audited by reading it. SwiftUI and the Foundation Models bridge sit on top and are the only parts that need a phone.

1. **SessionBuilder** picks the next few minutes. Items ramp from warm-up to stretch, because a session that opens with the hardest question mostly teaches people to quit, and question kinds are interleaved rather than blocked (Rohrer & Taylor, 2007): mixing kinds costs a little practice accuracy and buys a lot of retention.
2. **AnswerChecker** grades the answer. It parses decimals, fractions, mixed numbers, scientific notation, and units; normalises case, diacritics, punctuation, and articles for text answers; and allows a one-character typo on longer words so a slip is not scored as a misconception.
3. **MathEvaluator** is a small recursive-descent parser for arithmetic. It exists so a numeric answer can be *re-derived* rather than trusted — used both for curated content integrity and for anything the model proposes.
4. **SpacedRepetition** fits a forgetting half-life per lesson (half-life regression, Settles & Meeder, 2016) and schedules review when predicted recall drops below 0.7.
5. **MasteryModel** turns that record into the five states the path draws — locked, ready, learning, strong, mastered — and unlocks the next lesson once the previous one is cleared.
6. **ProgressEngine** applies the game rules: XP with a capped combo bonus, quadratic level thresholds, first-clear and perfect-session bonuses, the daily goal, and the streak.
7. **CoachService** and **PracticeGenerator** are the only two components that talk to Apple Intelligence, and neither of them is allowed to hand its output straight to a learner.

## Apple Intelligence, and what is done with it

`LanguageReasoner` is the single seam between Quark and Apple's on-device Foundation Models. When the model is available, every generation goes through it; when it is not, `HeuristicReasoner` reports `isAvailable == false` and the app runs entirely on curated content. Nothing in the app is allowed to *require* the model.

Two sampling profiles are used: `coaching` for hints and replies, and `exact` — greedy, low temperature — for anything that has to be checkable. Practice items use guided generation (`@Generable`) for shape, and the schema's constraints are treated as a hint to the model rather than a guarantee, because every one of them is re-checked afterwards.

The coach is steered by a six-line constitution, shown verbatim in Settings and used as the instruction block when a draft has to be revised rather than discarded:

> Teach, don't tell · Stay on the lesson · Be truthful · Be kind · Be private · Stay in your lane

When a draft fails a repairable check, the model gets exactly one rewrite against those principles (critique-and-revise, Bai et al., 2022). If the rewrite also fails, the curated text ships instead. A learner is never left staring at an error where a hint should be.

## Guardrails

Apple Intelligence has its own safety guardrails, and they run first — a refusal surfaces as `ReasonerError.blockedBySafetySystem` and is treated as a normal, expected outcome. These eleven are Quark's own: narrow, deterministic checks that decide whether model output is fit to put in front of someone who is trying to learn. They are separate from the model, they are testable without it, and each one can be read in a minute.

| Guardrail | What it does |
| --- | --- |
| **Shape** | A generated question must have four distinct options and exactly one marked correct. |
| **Safety** | Anything violent, sexual, self-harm related, or otherwise unsuitable is dropped, not softened. |
| **No personal data** | Names, emails, phone numbers, and links are stripped; the coach never asks for personal details. |
| **On syllabus** | Generated material has to use the vocabulary of the lesson it claims to belong to, and share terms with it. |
| **Arithmetic re-checked** | Numeric answers are re-derived from arithmetic by `MathEvaluator` before the question is shown. |
| **One right answer** | Duplicate options, "all of the above", and questions that contain their own answer are rejected. |
| **Readable** | Long sentences and jargon the lesson never introduced are rejected. |
| **Grounded in the lesson** | Every number in coach text must appear in the lesson facts or the question itself. |
| **Not a repeat** | A generated question that near-duplicates one already asked is discarded. |
| **No spoilers** | A hint that contains the answer is rewritten once, then replaced with the built-in hint. |
| **Short enough** | Coach replies are capped so a hint stays a hint. |

Failures are repaired where that is safe (a redaction, a trimmed sentence, one rewrite) and replaced with the lesson's built-in text where it is not. Rejection is never surfaced as an error.

Because "we have guardrails" is a claim rather than a fact, the app keeps a **guardrail ledger** for each session — reviewed, passed as written, edited before you saw it, replaced with built-in text — and shows it on the summary screen whenever Apple Intelligence contributed anything.

## Curriculum

Content ships with the binary: no download, no CDN, no request that could tell anyone what a learner is studying.

| Track | Units | Lessons | Questions |
| --- | --- | --- | --- |
| Mathematics | 2 | 4 | 20 |
| Physics | 2 | 4 | 20 |
| Chemistry | 2 | 4 | 20 |
| Biology | 2 | 4 | 20 |
| Computing | 2 | 4 | 20 |
| Data & Stats | 2 | 4 | 20 |

Each lesson also carries its syllabus in one-line form — 104 grounding facts across the curriculum. Those lines are the *only* material the on-device model is allowed to build hints and generated practice from, which is what keeps the coach inside the lesson rather than inside the internet.

## Testing

The engine layer is Foundation-only on purpose, so it builds and runs with a single `swiftc` invocation on macOS or Linux — no simulator, no device, no Apple Intelligence.

```bash
.tooling/run_unit_tests.sh        # 70 tests across the engine and guardrail layers
.tooling/run_guardrail_harness.sh # 36 adversarial scenarios against the guardrails
```

The second one is the interesting one. `GuardrailHarness` red-teams the guardrail layer with a scripted model that misbehaves on purpose: arithmetic that does not add up, four options where two are the same value, a physics question filed under fractions, a hint that states the answer, invented numbers, an email address in a reply, a prompt that contains its own answer. Every scenario names the guardrail that is supposed to catch it, and the run fails if the wrong one does.

```
Reviewed 25: accepted 4, repaired 6, rejected 15
  On syllabus                caught 7
  One right answer           caught 4
  No spoilers                caught 3
  Safety                     caught 2
  Readable                   caught 2
  Arithmetic re-checked      caught 2
  Not a repeat               caught 1
  Shape                      caught 1
  Grounded in the lesson     caught 1
Every guardrail caught what it was supposed to catch.
```

## What happens on your device

- **Coaching:** hints, explanations, and replies are generated on your device by Apple's on-device model, reviewed on your device, and shown on your device.
- **Generated practice:** bonus questions are written on your device and pass the full guardrail review before you see them. They are always labelled.
- **Progress:** XP, streak, and per-lesson skill records are stored in a single JSON file in the app's own container.
- **No network:** Quark makes no network calls at all. It works in airplane mode, and there is no account to create.
- **No analytics or tracking:** there is no analytics SDK, no advertising identifier, and no crash reporter in this app.

## Privacy Policy

**We do not collect your data.** Quark does **not** collect, store, or transmit any of your personal data, and we operate no backend that could receive it.

### What happens on your device

- **Learning content:** all 24 lessons and 120 questions ship inside the app. Nothing is fetched, so nothing about what you are studying is observable.
- **Coaching:** when Apple Intelligence is available, your question to the coach and the lesson's facts are given to Apple's on-device Foundation Models. That processing happens on your device. We do not send it anywhere.
- **Progress:** your XP, streak, daily goal, and per-lesson skill records are stored only in the app's local storage on your device. Reset in Settings deletes them immediately; deleting the app deletes them too.
- **No analytics or tracking:** Quark does not use analytics, advertising, or tracking SDKs. We do not collect device identifiers, usage statistics, or any other telemetry.
- **No network permission needed:** the app makes no outbound requests.

### Children

Quark asks for no personal information, has no account, no chat with other people, no advertising, and no in-app purchases. The coach is instructed never to request personal details, and the privacy guardrail strips names, emails, phone numbers, and links from anything it writes.

### Changes to this policy

If we change this policy (for example, to describe new features), we will update this page and the "Last updated" date in the app's Privacy screen.

### Contact

If you have questions about privacy or this policy, contact us using the support email listed on the Quark App Store page.

## Requirements

- iOS 26+ (deployment target). Apple Intelligence–capable devices get the on-device Foundation Models coach; every other device uses the built-in hints and explanations, and no feature disappears.
- Xcode 16+ (iOS 26 SDK + Foundation Models). Verified building with Xcode 26.
- Swift 6.1+ if you want to run the engine tests on Linux.

## Setup

1. Open `Quark.xcodeproj` in Xcode (app name: Quark - Learn STEM). The project is also described by `project.yml` for [XcodeGen](https://github.com/yonaskolb/XcodeGen); if you would rather not install it, `python3 .tooling/generate_xcodeproj.py` regenerates the checked-in project from the source tree.
2. Select your development team under Signing & Capabilities.
3. Build and run on a device (recommended — Apple Intelligence is unavailable in the Simulator, and the app will correctly fall back to built-in coaching there).
4. In-app **Settings** → **Guardrails** to read every check, and **How the coach behaves** for the constitution verbatim. Both Apple Intelligence switches can be turned off; the app stays complete.

## Layout

```
apps/Quark/
├── Quark/
│   ├── Models/           Track, Exercise, Course, LearnerProfile
│   ├── Curriculum/        Six courses plus the vocabulary index
│   ├── Services/
│   │   ├── Learning/     MathEvaluator, AnswerChecker, SpacedRepetition,
│   │   │                  MasteryModel, ProgressEngine, SessionBuilder
│   │   ├── Intelligence/ LanguageReasoner — the Foundation Models seam
│   │   ├── Coach/        CoachService, PracticeGenerator, persona, constitution
│   │   └── Guardrails/   The eleven checks, plus the ledger
│   ├── ViewModels/       SessionViewModel
│   ├── Theme/            QuarkTheme
│   └── Views/            Path, session, summary, progress, settings, onboarding
├── TestHarness/          Unit tests, scripted reasoner, adversarial harness
└── .tooling/             Test runners and the project/icon generators
```

## References

- Rohrer, D. & Taylor, K. (2007). *The shuffling of mathematics problems improves learning.* — interleaved practice
- Settles, B. & Meeder, B. (2016). *A trainable spaced repetition model for language learning.* — half-life regression
- Bai, Y. et al. (2022). *Constitutional AI: Harmlessness from AI Feedback.* — critique-and-revise

## Contact

Quark is a [Camou Labs](https://camoulabs.github.io) app. If you have questions about privacy, use the support email listed on the App Store page.
