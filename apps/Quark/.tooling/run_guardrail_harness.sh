#!/usr/bin/env bash
# Compile and run the guardrail red-team harness (see TestHarness/GuardrailHarness.swift).
#
# Everything below the UI — curriculum, grading, spaced repetition, scoring,
# and the whole guardrail layer — is Foundation-only by design, so it builds
# and runs with a single swiftc invocation on macOS or Linux. SwiftUI views and
# the FoundationModels bridge are deliberately excluded: they need a device.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.tooling/GuardrailHarness.bin"

SOURCES=(
  "$ROOT/Quark/Models/Track.swift"
  "$ROOT/Quark/Models/Exercise.swift"
  "$ROOT/Quark/Models/Course.swift"
  "$ROOT/Quark/Models/LearnerProfile.swift"
  "$ROOT/Quark/Curriculum/Curriculum.swift"
  "$ROOT/Quark/Curriculum/MathCourse.swift"
  "$ROOT/Quark/Curriculum/PhysicsCourse.swift"
  "$ROOT/Quark/Curriculum/ChemistryCourse.swift"
  "$ROOT/Quark/Curriculum/BiologyCourse.swift"
  "$ROOT/Quark/Curriculum/ComputingCourse.swift"
  "$ROOT/Quark/Curriculum/DataCourse.swift"
  "$ROOT/Quark/Services/Learning/MathEvaluator.swift"
  "$ROOT/Quark/Services/Learning/AnswerChecker.swift"
  "$ROOT/Quark/Services/Learning/SpacedRepetition.swift"
  "$ROOT/Quark/Services/Learning/MasteryModel.swift"
  "$ROOT/Quark/Services/Learning/ProgressEngine.swift"
  "$ROOT/Quark/Services/Learning/SeededRandom.swift"
  "$ROOT/Quark/Services/Learning/SessionBuilder.swift"
  "$ROOT/Quark/Services/Intelligence/LanguageReasoner.swift"
  "$ROOT/Quark/Services/Coach/QuarkPersona.swift"
  "$ROOT/Quark/Services/Coach/Constitution.swift"
  "$ROOT/Quark/Services/Coach/CoachService.swift"
  "$ROOT/Quark/Services/Coach/PracticeGenerator.swift"
  "$ROOT/Quark/Services/Guardrails/Guardrail.swift"
  "$ROOT/Quark/Services/Guardrails/SafetyScreen.swift"
  "$ROOT/Quark/Services/Guardrails/GroundingCheck.swift"
  "$ROOT/Quark/Services/Guardrails/AnswerLeakDetector.swift"
  "$ROOT/Quark/Services/Guardrails/ItemGuardrails.swift"
  "$ROOT/Quark/Services/Guardrails/CoachGuardrails.swift"
  "$ROOT/TestHarness/ScriptedReasoner.swift"
  "$ROOT/TestHarness/GuardrailHarness.swift"
)

if [[ "$(uname -s)" == "Darwin" ]]; then
  SDK="$(xcrun --sdk macosx --show-sdk-path)"
  xcrun swiftc \
    -sdk "$SDK" \
    -target arm64-apple-macos14.0 \
    -DQUARK_GUARDRAIL_HARNESS_MAIN \
    -parse-as-library \
    -o "$OUT" \
    "${SOURCES[@]}"
else
  swiftc \
    -DQUARK_GUARDRAIL_HARNESS_MAIN \
    -parse-as-library \
    -o "$OUT" \
    "${SOURCES[@]}"
fi

"$OUT"
