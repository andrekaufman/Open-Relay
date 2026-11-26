import SwiftUI

/// A calm animated orb. Listening: swells smoothly with your voice.
/// Thinking: a slow rotating arc. Speaking: soft ripples. Static with
/// Reduce Motion or in Always On.
struct OrbView: View {
    enum Mode { case idle, listening, thinking, speaking }
    let level: Double
    let mode: Mode
    let reduced: Bool

    /// Smoothed mic level so the orb doesn't jitter.
    @State private var smoothed: Double = 0

    var body: some View {
        animatedOrb
            .onChange(of: level) { _, new in
                // Fast rise, slower fall.
                smoothed = new > smoothed ? smoothed * 0.4 + new * 0.6 : smoothed * 0.8 + new * 0.2
            }
            .animation(.easeOut(duration: 0.12), value: smoothed)
            .animation(.easeInOut(duration: 0.3), value: mode)
    }

    private var animatedOrb: some View {
        TimelineView(timelineSchedule) { context in
            timelineOrb(at: context.date)
        }
    }

    private func timelineOrb(at date: Date) -> some View {
        let t = date.timeIntervalSinceReferenceDate
        let breathe = 0.5 + 0.5 * sin(t * 2.2)
        return orb(t: t, breathe: breathe)
    }

    private var timelineSchedule: AnimationTimelineSchedule {
        .animation(minimumInterval: 1.0 / 30.0, paused: reduced || mode == .idle)
    }

    private func orb(t: Double, breathe: Double) -> some View {
        ZStack {
            speakingRipples(t: t)
            orbCore(t: t, breathe: breathe)
            thinkingArc(t: t)
            outerRing(breathe: breathe)
        }
    }

    @ViewBuilder
    private func speakingRipples(t: Double) -> some View {
        if mode == .speaking && !reduced {
            ForEach(0..<2, id: \.self) { i in
                let phase = (t * 0.8 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                Circle()
                    .stroke(color.opacity(0.35 * (1 - phase)), lineWidth: 2)
                    .scaleEffect(0.85 + phase * 0.3)
            }
        }
    }

    private func orbCore(t: Double, breathe: Double) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.95), color.opacity(0.35)],
                                 center: .center, startRadius: 4, endRadius: 50))
            .scaleEffect(reduced ? 0.82 : scale(t: t, breathe: breathe))
    }

    @ViewBuilder
    private func thinkingArc(t: Double) -> some View {
        if mode == .thinking && !reduced {
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(t * 120))
                .scaleEffect(0.95)
        }
    }

    @ViewBuilder
    private func outerRing(breathe: Double) -> some View {
        if mode != .thinking || reduced {
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 2)
                .scaleEffect(reduced ? 0.9 : 0.95 + breathe * 0.03)
        }
    }

    private func scale(t: Double, breathe: Double) -> Double {
        switch mode {
        case .idle: return 0.82
        case .listening: return 0.84 + min(1, smoothed) * 0.2
        case .thinking: return 0.84 + breathe * 0.04
        case .speaking: return 0.88 + (0.5 + 0.5 * sin(t * 5)) * 0.06
        }
    }

    private var color: Color {
        switch mode {
        case .idle: return .gray
        case .listening: return .cyan
        case .thinking: return .indigo
        case .speaking: return .purple
        }
    }
}
