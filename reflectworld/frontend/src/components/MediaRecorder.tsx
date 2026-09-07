"use client";

import { useCallback, useRef, useState } from "react";

interface MediaRecorderProps {
  onRecorded: (file: File) => void;
  disabled?: boolean;
}

export default function MediaRecorder({ onRecorded, disabled }: MediaRecorderProps) {
  const [recording, setRecording] = useState(false);
  const [duration, setDuration] = useState(0);
  const mediaRecorderRef = useRef<globalThis.MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const startRecording = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new window.MediaRecorder(stream, { mimeType: "audio/webm" });
      chunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };

      recorder.onstop = () => {
        stream.getTracks().forEach((t) => t.stop());
        const blob = new Blob(chunksRef.current, { type: "audio/webm" });
        const file = new File([blob], `voice-note-${Date.now()}.webm`, { type: "audio/webm" });
        onRecorded(file);
        setDuration(0);
      };

      mediaRecorderRef.current = recorder;
      recorder.start();
      setRecording(true);
      timerRef.current = setInterval(() => setDuration((d) => d + 1), 1000);
    } catch {
      alert("Microphone access is required for voice notes.");
    }
  }, [onRecorded]);

  const stopRecording = useCallback(() => {
    if (mediaRecorderRef.current?.state === "recording") {
      mediaRecorderRef.current.stop();
    }
    if (timerRef.current) clearInterval(timerRef.current);
    setRecording(false);
  }, []);

  const formatDuration = (s: number) =>
    `${Math.floor(s / 60)}:${(s % 60).toString().padStart(2, "0")}`;

  return (
    <div className="flex items-center gap-2">
      {recording ? (
        <>
          <button
            onClick={stopRecording}
            className="relative w-10 h-10 rounded-full bg-red-500 text-white flex items-center justify-center recording-pulse"
          >
            <span className="w-3 h-3 bg-white rounded-sm" />
          </button>
          <span className="text-sm text-red-500 font-medium tabular-nums">
            {formatDuration(duration)}
          </span>
        </>
      ) : (
        <button
          onClick={startRecording}
          disabled={disabled}
          className="w-10 h-10 rounded-full bg-apple-bg border border-apple-border flex items-center justify-center hover:bg-apple-hover transition-colors disabled:opacity-50"
          title="Record voice note"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
            <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
            <line x1="12" y1="19" x2="12" y2="23" />
            <line x1="8" y1="23" x2="16" y2="23" />
          </svg>
        </button>
      )}
    </div>
  );
}
