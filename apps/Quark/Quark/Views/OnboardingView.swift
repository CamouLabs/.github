//
//  OnboardingView.swift
//  Quark
//
//  Three screens: what this is, how the intelligence works, and what you want
//  to learn. The middle screen is the one that matters — a learning app that
//  uses a language model owes the learner a plain account of what it will and
//  will not do before it starts.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var page = 0
    @State private var picked: Set<TrackID> = [.math, .physics]

    var body: some View {
        ZStack {
            QuarkTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcome.tag(0)
                    intelligence.tag(1)
                    trackPicker.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(QuarkTheme.settle, value: page)

                dots
                    .padding(.bottom, 18)

                PrimaryButton(
                    title: page == 2 ? "Start learning" : "Continue",
                    isEnabled: page < 2 || !picked.isEmpty
                ) {
                    if page < 2 {
                        withAnimation(QuarkTheme.settle) { page += 1 }
                    } else {
                        store.setTracks(TrackID.allCases.filter { picked.contains($0) })
                        store.completeOnboarding()
                    }
                }
                .padding(.horizontal, QuarkTheme.paddingH)
                .padding(.bottom, 22)
            }
        }
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == page ? QuarkTheme.primary : QuarkTheme.separator)
                    .frame(width: index == page ? 22 : 7, height: 7)
                    .animation(QuarkTheme.bounce, value: page)
            }
        }
    }

    // MARK: - Page 1

    private var welcome: some View {
        OnboardingPage(
            symbol: "atom",
            title: "STEM, five minutes at a time",
            subtitle: "Six tracks, short sessions, and a path that sends you back to whatever is starting to fade."
        ) {
            VStack(spacing: 10) {
                ForEach([TrackID.math, .physics, .chemistry, .biology, .computing, .data]) { track in
                    HStack(spacing: 12) {
                        Image(systemName: track.symbol)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(QuarkTheme.color(for: track))
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(QuarkTheme.color(for: track).opacity(0.12))
                            )
                        Text(track.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(QuarkTheme.textPrimary)
                        Spacer()
                        Text(track.blurb)
                            .font(.system(size: 13))
                            .foregroundStyle(QuarkTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Page 2

    private var intelligence: some View {
        OnboardingPage(
            symbol: "sparkles",
            title: "A coach that stays in its lane",
            subtitle: "Apple Intelligence writes hints, explanations, and bonus questions — on this device, and only after they pass Quark's own checks."
        ) {
            VStack(spacing: 12) {
                promise(
                    "checkmark.shield.fill",
                    "Eleven guardrails",
                    "Arithmetic is re-derived, hints that leak the answer are rewritten, and anything off-syllabus is dropped.",
                    QuarkTheme.correct
                )
                promise(
                    "iphone",
                    "Nothing leaves this iPhone",
                    "No account, no network calls, no analytics. Your progress is one file in the app's own container.",
                    QuarkTheme.primary
                )
                promise(
                    "book.closed.fill",
                    "It works without the model",
                    "Every lesson ships with written hints and explanations, so Quark is complete even with the coach off.",
                    QuarkTheme.spark
                )
            }
        }
    }

    private func promise(_ symbol: String, _ title: String, _ detail: String, _ tint: Color) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(QuarkTheme.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(QuarkTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Page 3

    private var trackPicker: some View {
        OnboardingPage(
            symbol: "checklist",
            title: "Pick your tracks",
            subtitle: "Two is a good start. You can change this any time in Settings."
        ) {
            VStack(spacing: 10) {
                ForEach(TrackID.allCases) { track in
                    let isPicked = picked.contains(track)
                    Button {
                        withAnimation(QuarkTheme.bounce) {
                            if isPicked { picked.remove(track) } else { picked.insert(track) }
                        }
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: track.symbol)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isPicked ? QuarkTheme.textInverse : QuarkTheme.color(for: track))
                                .frame(width: 34, height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(QuarkTheme.color(for: track).opacity(isPicked ? 1 : 0.12))
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(track.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(QuarkTheme.textPrimary)
                                Text(track.blurb)
                                    .font(.system(size: 12))
                                    .foregroundStyle(QuarkTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: isPicked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(isPicked ? QuarkTheme.color(for: track) : QuarkTheme.separator)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                                .fill(QuarkTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: QuarkTheme.chipRadius, style: .continuous)
                                .strokeBorder(
                                    isPicked ? QuarkTheme.color(for: track) : QuarkTheme.separator,
                                    lineWidth: isPicked ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityAddTraits(isPicked ? [.isSelected] : [])
                }
            }
        }
    }
}

private struct OnboardingPage<Content: View>: View {
    let symbol: String
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(QuarkTheme.textInverse)
                    .frame(width: 62, height: 62)
                    .background(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .fill(LinearGradient(
                                colors: [QuarkTheme.primary, QuarkTheme.primaryDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .padding(.top, 36)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(QuarkTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(QuarkTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                content
                    .padding(.top, 4)
            }
            .padding(.horizontal, QuarkTheme.paddingH)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
