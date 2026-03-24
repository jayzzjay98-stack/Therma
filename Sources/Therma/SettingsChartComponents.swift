import SwiftUI

struct SettingsCircularUsageGauge: View {
    let progress: Double
    let value: String
    let caption: String
    let tint: Color
    let valueFontSize: CGFloat
    let captionFontSize: CGFloat

    init(
        progress: Double,
        value: String,
        caption: String,
        tint: Color,
        valueFontSize: CGFloat = 32,
        captionFontSize: CGFloat = 10
    ) {
        self.progress = progress
        self.value = value
        self.caption = caption
        self.tint = tint
        self.valueFontSize = valueFontSize
        self.captionFontSize = captionFontSize
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 12)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.75), tint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.40), radius: 12)

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: valueFontSize, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(caption.uppercased())
                    .font(.system(size: captionFontSize, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.23, green: 0.35, blue: 0.42))
                    .tracking(1)
            }
        }
    }
}

struct SettingsChartHeroCard: View {
    let eyebrow: String
    let value: String
    let trend: String
    let trendColor: Color
    let stats: [(String, String)]
    let values: [Double]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.42))
                        .tracking(1.6)

                    HStack(alignment: .bottom, spacing: 10) {
                        Text(value)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()

                        Text(trend)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(trendColor)
                            .padding(.bottom, 5)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 28) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stat.0.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.32))
                                .tracking(1)
                            Text(stat.1)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                        .padding(.leading, index == 0 ? 20 : 0)
                        .overlay(alignment: .leading) {
                            if index == 0 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(width: 1, height: 44)
                                    .offset(x: -12)
                            }
                        }
                    }
                }
            }

            SettingsGlowingAreaChart(values: values, tint: tint)
                .frame(height: 108)
        }
        .padding(14)
        .background(SettingsDashboardCardBackground(accent: tint))
    }
}

struct SettingsGlowingAreaChart: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let normalized = normalizedValues

            ZStack {
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 1)
                        Spacer(minLength: 0)
                    }
                }

                SettingsAreaFillShape(values: normalized)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.20), tint.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                SettingsLineChartShape(values: normalized)
                    .stroke(tint.opacity(0.22), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                    .blur(radius: 6)

                SettingsLineChartShape(values: normalized)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: tint.opacity(0.55), radius: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private static let placeholderValues: [Double] = [0.18, 0.22, 0.20, 0.44, 0.18, 0.75, 0.38]

    private var normalizedValues: [Double] {
        let raw = values.isEmpty ? Self.placeholderValues : values
        let minValue = raw.min() ?? 0
        let maxValue = raw.max() ?? 1
        let spread = max(maxValue - minValue, 0.001)
        return raw.map { 0.10 + (($0 - minValue) / spread) * 0.72 }
    }
}

private struct SettingsLineChartShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }

        let points = values.enumerated().map { index, value in
            CGPoint(
                x: rect.minX + CGFloat(index) * rect.width / CGFloat(values.count - 1),
                y: rect.maxY - CGFloat(value) * rect.height
            )
        }

        var path = Path()
        path.move(to: points[0])

        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let midX = (previous.x + current.x) / 2
            path.addCurve(
                to: current,
                control1: CGPoint(x: midX, y: previous.y),
                control2: CGPoint(x: midX, y: current.y)
            )
        }

        return path
    }
}

private struct SettingsAreaFillShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count > 1 else { return Path() }
        let line = SettingsLineChartShape(values: values).path(in: rect)
        var path = line
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SettingsNetworkTrafficCard: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let downloadValue: String
    let uploadValue: String
    let downBars: [Double]
    let upBars: [Double]
    let tint: Color
    let secondaryTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NETWORK THROUGHPUT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
                        .tracking(1.4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    SettingsLegendDot(label: "DOWN", color: tint)
                    SettingsLegendDot(label: "UP", color: secondaryTint)
                }
            }

            SettingsNetworkBarChart(
                downBars: downBars,
                upBars: upBars,
                downColor: tint,
                upColor: secondaryTint
            )
            .frame(height: 58)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                SettingsTransferStat(title: "Download", value: downloadValue, icon: "arrow.down", tint: tint)
                SettingsTransferStat(title: "Upload", value: uploadValue, icon: "arrow.up", tint: secondaryTint)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SettingsDashboardCardBackground(accent: tint))
        .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
    }
}

private struct SettingsLegendDot: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
        }
    }
}

private struct SettingsNetworkBarChart: View {
    let downBars: [Double]
    let upBars: [Double]
    let downColor: Color
    let upColor: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(zip(paddedDown.indices, paddedDown)), id: \.0) { index, down in
                let up = paddedUp[index]
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(downColor.opacity(index == 2 ? 0.95 : 0.24))
                        .frame(height: 46 * down)
                        .shadow(color: index == 2 ? downColor.opacity(0.40) : .clear, radius: 10)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(upColor.opacity(index == 2 ? 0.95 : 0.30))
                        .frame(height: 18 * up)
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
    }

    private var paddedDown: [CGFloat] {
        normalized(downBars)
    }

    private var paddedUp: [CGFloat] {
        normalized(upBars)
    }

    private func normalized(_ values: [Double]) -> [CGFloat] {
        let source = values.isEmpty ? [0.30, 0.62, 1.0, 0.48, 0.76] : values
        return source.map { CGFloat(min(max($0, 0.16), 1.0)) }
    }
}

private struct SettingsTransferStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(tint.opacity(0.10))
                    )

                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.54))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.6)
                )
        )
    }
}
