import SwiftUI

struct GPUMenuBarView: View {
    let gpuMonitor: GPUMonitor
    let openSettingsAction: () -> Void

    private let theme = AppTheme.midnightAurora

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection
            footerSection
        }
        .frame(width: Constants.menuBarWidth)
        .background(theme.bgColor)
        .environment(\.appTheme, theme)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "display")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            Text("GPU")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
            Text("·")
                .foregroundStyle(.white.opacity(0.3))
            Text(gpuMonitor.displayValue)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.accent)
                .monospacedDigit()
            Spacer()
        }
        .padding(.vertical, 11)
        .background(
            LinearGradient(
                colors: [theme.accent.opacity(0.08), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(spacing: 0) {
            // Big utilization number
            utilizationDisplay
            // Stats grid
            statsGrid
        }
        .padding(.vertical, 10)
    }

    private var utilizationDisplay: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("GPU UTILIZATION")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.8)
                    .padding(.bottom, 4)

                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(gpuUsageString)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(utilizationColor)
                        .shadow(color: utilizationColor.opacity(0.3), radius: 10)
                        .monospacedDigit()
                    Text("%")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(utilizationColor.opacity(0.5))
                }

                // Pill bar
                utilizationBar
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }

            Spacer()

            // Circular gauge
            circularGauge
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var utilizationBar: some View {
        GeometryReader { geo in
            let total = max(8, Int(geo.size.width / Constants.segmentItemWidth))
            let filled = Int((Double(gpuMonitor.usagePercent ?? 0) / 100.0) * Double(total))
            HStack(spacing: Constants.segmentSpacing) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor(i, filled: filled))
                        .frame(height: barHeight(i, total: total))
                }
            }
        }
        .frame(height: Constants.segmentBarHeight)
    }

    private func barColor(_ i: Int, filled: Int) -> Color {
        if i < filled      { return theme.accent }
        if i == filled     { return theme.accent.opacity(0.35) }
        return Color.white.opacity(0.05)
    }

    private func barHeight(_ i: Int, total: Int) -> CGFloat {
        let mid = Double(total) / 2.0
        return CGFloat(Double(Constants.segmentBarHeight) - abs(Double(i) - mid) * Constants.segmentHeightDropFactor)
    }

    private var circularGauge: some View {
        let progress = (gpuMonitor.usagePercent ?? 0) / 100.0
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: Constants.miniRingLineWidth)
                .frame(width: Constants.miniRingSize, height: Constants.miniRingSize)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [theme.accent.opacity(0.6), theme.accent, theme.accent.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: Constants.miniRingLineWidth, lineCap: .round)
                )
                .frame(width: Constants.miniRingSize, height: Constants.miniRingSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.4), radius: 6)
            VStack(spacing: 1) {
                Text(gpuUsageString)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("GPU")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.accent.opacity(0.8))
                    .tracking(0.5)
            }
        }
    }

    private var statsGrid: some View {
        HStack(spacing: 4) {
            MenuStatBox(
                label: "RENDERER",
                value: gpuMonitor.rendererDisplayValue,
                isOk: false
            )
            MenuStatBox(
                label: "TILER",
                value: gpuMonitor.tilerDisplayValue,
                isOk: false
            )
            MenuStatBox(
                label: "VRAM",
                value: gpuMonitor.vramDisplayValue,
                isOk: false
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }

    // MARK: - Footer

    private var footerSection: some View {
        MenuFooterBar(openSettingsAction: openSettingsAction)
    }

    // MARK: - Helpers

    private var gpuUsageString: String {
        guard let pct = gpuMonitor.usagePercent else { return "--" }
        return "\(Int(pct.rounded()))"
    }

    private var utilizationColor: Color {
        theme.accent
    }
}
