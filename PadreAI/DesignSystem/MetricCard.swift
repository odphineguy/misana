//
//  MetricCard.swift
//  MiSana — Premium 2x2 health card
//
//  Match for the JSX `MDMetricCard` in the design exploration.
//  Pass real HealthKit data via `value`, `unit`, and `history`.
//
//  Usage:
//      MetricCard(
//          icon: "heart.fill",
//          iconColor: .miSana.heart,
//          iconBackground: .miSana.cardSoftPink,
//          label: "Ritmo cardíaco",
//          value: "\(heartRate)",
//          unit: "BPM",
//          history: heartRateHistory,        // [Double]
//          sparkColor: .miSana.heart,
//          sparkStyle: .line,
//          isLive: true
//      )
//

import SwiftUI

struct MetricCard: View {
    enum SparkStyle { case line, bars }

    let icon: String                // SF Symbol name
    let iconColor: Color
    let iconBackground: Color
    let label: String
    let value: String               // Pre-formatted display value (e.g. "8,089" or "6.2")
    var unit: String? = nil
    var valueText: Text? = nil      // Optional pre-styled rich text for value (overrides plain `value` rendering)
    let history: [Double]           // Last N data points for sparkline
    let sparkColor: Color
    var sparkStyle: SparkStyle = .line
    var isLive: Bool = false        // Show pulsing "LIVE" indicator
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: icon chip + label + (LIVE | ⋯)
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconBackground)
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.miSana.fg)

                Spacer()

                if isLive {
                    HStack(spacing: 4) {
                        PulseDot(color: sparkColor)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(.miSana.fg3)
                    }
                } else {
                    Text("···")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.miSana.fg3)
                }
            }

            // Sparkline
            if !history.isEmpty {
                Group {
                    switch sparkStyle {
                    case .line: SparklineLine(data: history, color: sparkColor)
                    case .bars: SparklineBars(data: history, color: sparkColor)
                    }
                }
                .frame(height: 44)
            }

            // Value + unit
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Group {
                    if let valueText {
                        valueText
                    } else {
                        Text(value)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.miSana.fg)
                            .tracking(-0.6)
                    }
                }
                if let unit {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.miSana.fg2)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 130)
        .background(Color.miSana.card)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color.miSana.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .onTapGesture { onTap?() }
        .animation(.easeInOut(duration: 0.6), value: history)
        .animation(.easeInOut(duration: 0.6), value: value)
    }
}

// MARK: - Sparkline (line)
private struct SparklineLine: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                Path { p in
                    guard let first = pts.first else { return }
                    p.move(to: first)
                    for pt in pts.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if let last = pts.last {
                    Circle()
                        .fill(color)
                        .frame(width: 7, height: 7)
                        .position(last)
                }
            }
        }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let pad: CGFloat = 4
        let maxV = data.max() ?? 1
        let minV = data.min() ?? 0
        let range = max(maxV - minV, 0.0001)
        let w = size.width
        let h = size.height
        return data.enumerated().map { i, v in
            let x = pad + (CGFloat(i) / CGFloat(max(data.count - 1, 1))) * (w - pad * 2)
            let y = h - pad - CGFloat((v - minV) / range) * (h - pad * 2)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Sparkline (bars)
private struct SparklineBars: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let maxV = data.max() ?? 1
            let count = max(data.count, 1)
            let gap: CGFloat = 2
            let bw = (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count)
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(Array(data.enumerated()), id: \.offset) { i, v in
                    let h = CGFloat(v / maxV) * (geo.size.height - 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(i == data.count - 1 ? 1.0 : 0.45))
                        .frame(width: bw, height: max(h, 2))
                }
            }
        }
    }
}

// MARK: - Pulse dot
private struct PulseDot: View {
    let color: Color
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.45), lineWidth: 1)
                .frame(width: pulsing ? 16 : 7, height: pulsing ? 16 : 7)
                .opacity(pulsing ? 0 : 1)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}
