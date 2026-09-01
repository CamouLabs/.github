"use client";

import { MemoryEdge, MemoryNode } from "@/lib/api";

const TIER_COLORS: Record<string, string> = {
  perceptual: "border-blue-200 bg-blue-50",
  reflective: "border-purple-200 bg-purple-50",
};

const ENTITY_ICONS: Record<string, string> = {
  event: "📅",
  emotion: "💗",
  theme: "🏷️",
  insight: "💡",
  person: "👤",
};

interface MemoryViewProps {
  nodes: MemoryNode[];
  edges: MemoryEdge[];
  open: boolean;
  onClose: () => void;
}

export default function MemoryView({ nodes, edges, open, onClose }: MemoryViewProps) {
  if (!open) return null;

  const reflective = nodes.filter((n) => n.tier === "reflective");
  const perceptual = nodes.filter((n) => n.tier === "perceptual");

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[80vh] flex flex-col animate-fade-in">
        <div className="p-6 border-b border-apple-border flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-apple-text">Memory Graph</h2>
            <p className="text-sm text-apple-secondary">
              {nodes.length} memories · {edges.length} connections
            </p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg hover:bg-apple-hover flex items-center justify-center text-apple-secondary"
          >
            ✕
          </button>
        </div>

        <div className="flex-1 overflow-y-auto scrollbar-thin p-6 space-y-6">
          {reflective.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-apple-secondary uppercase tracking-wide mb-3">
                Reflective Memories
              </h3>
              <div className="space-y-2">
                {reflective.map((node) => {
                  const connected = edges.filter(
                    (e) => e.source_id === node.id || e.target_id === node.id
                  );
                  return (
                    <div
                      key={node.id}
                      className={`p-3 rounded-xl border ${TIER_COLORS.reflective}`}
                    >
                      <div className="flex items-start gap-2">
                        <span>{ENTITY_ICONS[node.entity_type] || "💡"}</span>
                        <div className="flex-1">
                          <p className="text-sm text-apple-text leading-relaxed">{node.content}</p>
                          <div className="flex items-center gap-3 mt-2 text-xs text-apple-secondary">
                            <span>Salience: {(node.salience * 100).toFixed(0)}%</span>
                            <span>Sticky: {(node.sticky_score * 100).toFixed(0)}%</span>
                            {connected.length > 0 && (
                              <span>{connected.length} links</span>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          )}

          {perceptual.length > 0 && (
            <section>
              <h3 className="text-xs font-semibold text-apple-secondary uppercase tracking-wide mb-3">
                Perceptual Memories
              </h3>
              <div className="space-y-2">
                {perceptual.slice(0, 20).map((node) => (
                  <div
                    key={node.id}
                    className={`p-3 rounded-xl border ${TIER_COLORS.perceptual}`}
                  >
                    <div className="flex items-start gap-2">
                      <span>{ENTITY_ICONS[node.entity_type] || "📅"}</span>
                      <p className="text-sm text-apple-text leading-relaxed flex-1">
                        {node.content}
                      </p>
                    </div>
                  </div>
                ))}
                {perceptual.length > 20 && (
                  <p className="text-xs text-apple-secondary text-center">
                    +{perceptual.length - 20} more perceptual memories
                  </p>
                )}
              </div>
            </section>
          )}

          {nodes.length === 0 && (
            <div className="text-center py-12">
              <p className="text-2xl mb-2">🧠</p>
              <p className="text-sm text-apple-secondary">
                Your memory graph will grow as you journal and reflect.
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
