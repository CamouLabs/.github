"use client";

import { Insight, markInsightRead } from "@/lib/api";

const TYPE_CONFIG: Record<string, { icon: string; label: string; color: string }> = {
  reminder: { icon: "💭", label: "Reminder", color: "bg-purple-50 text-purple-700" },
  pattern: { icon: "🔗", label: "Pattern", color: "bg-blue-50 text-blue-700" },
  encouragement: { icon: "🌟", label: "Encouragement", color: "bg-amber-50 text-amber-700" },
  reflection_question: { icon: "🪞", label: "Reflection", color: "bg-green-50 text-green-700" },
};

interface InsightsPanelProps {
  insights: Insight[];
  onRefresh: () => void;
  onInsightRead: (id: string) => void;
  generating: boolean;
}

export default function InsightsPanel({
  insights,
  onRefresh,
  onInsightRead,
  generating,
}: InsightsPanelProps) {
  const handleRead = async (id: string) => {
    await markInsightRead(id);
    onInsightRead(id);
  };

  const unread = insights.filter((i) => !i.read);

  return (
    <aside className="w-80 min-w-[280px] bg-apple-bg border-l border-apple-border flex flex-col h-full">
      <div className="p-4 border-b border-apple-border bg-white">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-semibold text-apple-text">Insights</h2>
          <button
            onClick={onRefresh}
            disabled={generating}
            className="text-xs text-apple-accent hover:underline disabled:opacity-50"
          >
            {generating ? "Generating..." : "Generate"}
          </button>
        </div>
        {unread.length > 0 && (
          <p className="text-xs text-apple-secondary mt-1">
            {unread.length} new insight{unread.length !== 1 ? "s" : ""}
          </p>
        )}
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin p-3 space-y-3">
        {insights.length === 0 ? (
          <div className="text-center py-12 animate-fade-in">
            <p className="text-2xl mb-2">🌸</p>
            <p className="text-sm text-apple-secondary">
              Insights will appear as you journal and reflect.
            </p>
          </div>
        ) : (
          insights.map((insight) => {
            const config = TYPE_CONFIG[insight.type] || TYPE_CONFIG.reflection_question;
            return (
              <div
                key={insight.id}
                className={`p-4 rounded-xl bg-white shadow-sm animate-fade-in transition-opacity ${
                  insight.read ? "opacity-60" : ""
                }`}
                onClick={() => !insight.read && handleRead(insight.id)}
              >
                <div className="flex items-center gap-2 mb-2">
                  <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${config.color}`}>
                    {config.icon} {config.label}
                  </span>
                  {!insight.read && (
                    <span className="w-2 h-2 rounded-full bg-apple-accent" />
                  )}
                </div>
                <p className="text-sm text-apple-text leading-relaxed">{insight.content}</p>
                <p className="text-xs text-apple-secondary mt-2">
                  {new Date(insight.created_at).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    hour: "numeric",
                    minute: "2-digit",
                  })}
                </p>
              </div>
            );
          })
        )}
      </div>
    </aside>
  );
}
