"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Entry, processEntry, updateEntry, uploadMediaEntry } from "@/lib/api";
import MediaRecorder from "./MediaRecorder";

const MOODS = [
  { id: "peaceful", label: "Peaceful", emoji: "🌿" },
  { id: "happy", label: "Happy", emoji: "☀️" },
  { id: "grateful", label: "Grateful", emoji: "🙏" },
  { id: "contemplative", label: "Contemplative", emoji: "🌙" },
  { id: "anxious", label: "Anxious", emoji: "🌊" },
  { id: "sad", label: "Sad", emoji: "💧" },
  { id: "hopeful", label: "Hopeful", emoji: "🌱" },
  { id: "tired", label: "Tired", emoji: "😴" },
];

interface EntryEditorProps {
  entry: Entry | null;
  onUpdate: (entry: Entry) => void;
  onProcessed: () => void;
}

export default function EntryEditor({ entry, onUpdate, onProcessed }: EntryEditorProps) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [mood, setMood] = useState<string | undefined>();
  const [saving, setSaving] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (entry) {
      setTitle(entry.title);
      setContent(entry.content);
      setMood(entry.mood);
    } else {
      setTitle("");
      setContent("");
      setMood(undefined);
    }
  }, [entry?.id]);

  const save = useCallback(async () => {
    if (!entry) return;
    setSaving(true);
    try {
      const updated = await updateEntry(entry.id, { title, content, mood });
      onUpdate(updated);
    } finally {
      setSaving(false);
    }
  }, [entry, title, content, mood, onUpdate]);

  const debouncedSave = useCallback(() => {
    if (saveTimer.current) clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(save, 800);
  }, [save]);

  const handleProcess = async () => {
    if (!entry) return;
    setProcessing(true);
    try {
      await save();
      await processEntry(entry.id);
      onProcessed();
    } finally {
      setProcessing(false);
    }
  };

  const handleVoiceRecorded = async (file: File) => {
    setUploading(true);
    try {
      const newEntry = await uploadMediaEntry(file, title || undefined, mood || undefined);
      onUpdate(newEntry);
      onProcessed();
    } catch (e) {
      alert("Failed to process voice note. Is the backend running?");
    } finally {
      setUploading(false);
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const newEntry = await uploadMediaEntry(file, title || undefined, mood || undefined);
      onUpdate(newEntry);
      onProcessed();
    } catch {
      alert("Failed to upload media.");
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  if (!entry) {
    return (
      <div className="flex-1 flex items-center justify-center text-apple-secondary">
        <div className="text-center animate-fade-in">
          <p className="text-2xl mb-2">✨</p>
          <p className="text-lg font-medium text-apple-text mb-1">Welcome to ReflectWorld</p>
          <p className="text-sm">Select an entry or create a new one to begin reflecting.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col h-full bg-white">
      <div className="px-8 pt-6 pb-3 border-b border-apple-border">
        <input
          type="text"
          value={title}
          onChange={(e) => {
            setTitle(e.target.value);
            debouncedSave();
          }}
          placeholder="Title"
          className="w-full text-2xl font-semibold text-apple-text bg-transparent border-none placeholder-apple-secondary"
        />
        <div className="flex items-center gap-2 mt-3 flex-wrap">
          {MOODS.map((m) => (
            <button
              key={m.id}
              onClick={() => {
                setMood(mood === m.id ? undefined : m.id);
                debouncedSave();
              }}
              className={`px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${
                mood === m.id
                  ? "bg-apple-accent/15 text-apple-accent"
                  : "bg-apple-bg text-apple-secondary hover:bg-apple-hover"
              }`}
            >
              {m.emoji} {m.label}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin px-8 py-4">
        {entry.transcript && entry.media_type !== "text" && (
          <div className="mb-4 p-3 bg-apple-bg rounded-xl">
            <p className="text-xs font-medium text-apple-secondary mb-1 uppercase tracking-wide">
              Transcript
            </p>
            <p className="text-sm text-apple-text leading-relaxed">{entry.transcript}</p>
          </div>
        )}
        <textarea
          value={content}
          onChange={(e) => {
            setContent(e.target.value);
            debouncedSave();
          }}
          placeholder="What's on your mind today?"
          className="w-full min-h-[300px] text-base text-apple-text bg-transparent border-none resize-none leading-relaxed placeholder-apple-secondary"
        />
      </div>

      <div className="px-8 py-4 border-t border-apple-border flex items-center justify-between">
        <div className="flex items-center gap-3">
          <MediaRecorder onRecorded={handleVoiceRecorded} disabled={uploading} />
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="w-10 h-10 rounded-full bg-apple-bg border border-apple-border flex items-center justify-center hover:bg-apple-hover transition-colors disabled:opacity-50"
            title="Upload audio or video"
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
              <polyline points="17 8 12 3 7 8" />
              <line x1="12" y1="3" x2="12" y2="15" />
            </svg>
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="audio/*,video/*"
            className="hidden"
            onChange={handleFileUpload}
          />
          {uploading && (
            <span className="text-sm text-apple-secondary">Processing media...</span>
          )}
        </div>

        <div className="flex items-center gap-3">
          {saving && <span className="text-xs text-apple-secondary">Saving...</span>}
          <button
            onClick={handleProcess}
            disabled={processing || !content.trim()}
            className="px-4 py-2 rounded-lg bg-apple-accent text-white text-sm font-medium hover:bg-blue-600 transition-colors disabled:opacity-50"
          >
            {processing ? "Reflecting..." : entry.processed ? "Re-reflect" : "Reflect & Remember"}
          </button>
        </div>
      </div>
    </div>
  );
}
