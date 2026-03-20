import SwiftUI

struct MenuBarLabel: View {
    let usagePercent: Int
    let cpuValue: String
    let displayMode: MonitorDisplayMode
    let iconSize: Double
    let textSize: Double

    var body: some View {
        labelArtwork
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
    }

    private var labelArtwork: some View {
        HStack(spacing: max(2, clampedTextSize * 0.25)) {
            Image(systemName: iconName)
                .font(.system(size: clampedIconSize, weight: .regular, design: .default))
            Text(primaryText)
                .font(.system(size: clampedTextSize, weight: .regular, design: .default))
            if let secondaryText {
                Text(secondaryText)
                    .font(.system(size: max(8, clampedTextSize - 1), weight: .regular, design: .default))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .foregroundStyle(.white)
    }

    private var iconName: String {
        switch displayMode {
        case .memory: return "cpu"
        case .cpu:    return "thermometer.medium"
        case .both:   return "gauge.with.dots.needle.50percent"
        }
    }

    private var primaryText: String {
        switch displayMode {
        case .memory:
            return "\(usagePercent)%"
        case .cpu:
            return cpuValue
        case .both:
            return "\(usagePercent)%"
        }
    }

    private var secondaryText: String? {
        switch displayMode {
        case .both:
            return cpuValue
        case .memory, .cpu:
            return nil
        }
    }

    private var clampedIconSize: Double {
        min(max(iconSize, Constants.minimumMenuBarIconSize), Constants.maximumMenuBarIconSize)
    }

    private var clampedTextSize: Double {
        min(max(textSize, Constants.minimumMenuBarTextSize), Constants.maximumMenuBarTextSize)
    }
}
