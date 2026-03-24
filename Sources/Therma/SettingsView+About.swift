import SwiftUI

extension SettingsView {
    var aboutPane: some View {
        VStack(alignment: .leading, spacing: 28) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                selectedTheme.cardBgColor.opacity(1.0),
                                selectedTheme.accent.opacity(0.08),
                                Color.white.opacity(0.015)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(selectedTheme.cardBorderColor, lineWidth: 0.9)
                    )

                RadialGradient(
                    colors: [selectedTheme.accent.opacity(0.12), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 220
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 18) {
                    Spacer(minLength: 0)

                    VStack(alignment: .center, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [selectedTheme.accent.opacity(0.22), selectedTheme.accent.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedTheme.accent.opacity(0.24), lineWidth: 1)
                                )
                                .frame(width: 86, height: 86)

                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        Text("THERMA")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .tracking(1.8)

                        Text("System temperature and performance telemetry for your menu bar.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.64))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }

                    Spacer(minLength: 0)
                }
                .padding(22)
            }
            .frame(height: 156)
            .padding(.bottom, 10)

            HStack(alignment: .top, spacing: 18) {
                aboutInfoPanel
                aboutUpdatePanel
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
    }

    var aboutInfoPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            aboutColumnTitle("Application")

            VStack(alignment: .leading, spacing: 14) {
                aboutFactRow(
                    icon: "shippingbox",
                    title: "Version",
                    value: "Therma \(Constants.appVersion)"
                )
                aboutFactRow(
                    icon: "desktopcomputer",
                    title: "Platform",
                    value: "Apple Silicon · macOS 14+"
                )
                aboutFactRow(
                    icon: "menubar.rectangle",
                    title: "Focus",
                    value: "Live RAM, CPU, battery, and network monitoring"
                )
            }
            .padding(18)
            .background(aboutPanelBackground)
            .frame(maxWidth: .infinity, minHeight: 244, maxHeight: 244, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var aboutUpdatePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            aboutColumnTitle("Software Update")

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(updateStatusColor.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(updateStatusColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Update Channel")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Text(updateStatusLabel)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(updateStatusColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(updateStatusColor.opacity(0.10))
                                        .overlay(
                                            Capsule()
                                                .stroke(updateStatusColor.opacity(0.22), lineWidth: 0.6)
                                        )
                                )
                        }

                        Text(updateSubtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)

                        if let detail = updateDetailMessage {
                            Text(detail)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(updateStatusColor.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Divider()
                    .overlay(Color.white.opacity(0.06))

                HStack {
                    Text("Current Build")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.54))

                    Spacer(minLength: 0)

                    Text(Constants.appVersion)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                HStack {
                    updateControls
                    Spacer(minLength: 0)
                }
            }
            .padding(18)
            .background(aboutPanelBackground)
            .frame(maxWidth: .infinity, minHeight: 244, maxHeight: 244, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var updateSubtitle: String {
        switch updateManager.state {
        case .idle:                       return "v\(Constants.appVersion) installed"
        case .checking:                   return "Checking GitHub releases..."
        case .upToDate:                   return "You're up to date"
        case .available(let version, _):  return "v\(version) is ready to download"
        case .downloading:                return "Downloading the verified release package..."
        case .downloaded(let version, _): return "v\(version) is ready to install"
        case .installing:                 return "Installing and relaunching Therma..."
        case .failed:                     return "The last update attempt did not complete"
        }
    }

    var updateStatusLabel: String {
        switch updateManager.state {
        case .idle: return "INSTALLED"
        case .checking: return "CHECKING"
        case .upToDate: return "CURRENT"
        case .available: return "AVAILABLE"
        case .downloading: return "DOWNLOADING"
        case .downloaded: return "READY"
        case .installing: return "INSTALLING"
        case .failed: return "ERROR"
        }
    }

    var updateStatusColor: Color {
        switch updateManager.state {
        case .failed:
            return Color(red: 0.96, green: 0.54, blue: 0.36)
        case .upToDate, .idle:
            return Color(red: 0.30, green: 0.88, blue: 0.55)
        default:
            return selectedTheme.accent
        }
    }

    var updateDetailMessage: String? {
        switch updateManager.state {
        case .idle:
            return "The installed build is ready. You can check GitHub for a newer release at any time."
        case .checking:
            return "Therma is requesting the latest release metadata from GitHub."
        case .upToDate:
            return "No newer public release was found for this channel."
        case .available:
            return "A matching release asset was found and passed initial URL validation."
        case .downloading:
            return "The update package is being downloaded before local verification."
        case .downloaded:
            return "The package is stored locally and waiting for install and relaunch."
        case .installing:
            return "Therma is validating the bundle and preparing a staged replacement."
        case .failed(let message):
            return message
        }
    }

    @ViewBuilder
    var updateControls: some View {
        switch updateManager.state {
        case .idle:
            Button("Check Now") { updateManager.checkForUpdates() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selectedTheme.accent)

        case .failed:
            Button("Check Again") {
                updateManager.resetToIdle()
                updateManager.checkForUpdates()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(updateStatusColor)

        case .checking, .downloading, .installing:
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini).scaleEffect(0.85)
                Text(updateStatusLabel.capitalized)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.50))
            }

        case .upToDate:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.30, green: 0.88, blue: 0.55))
                    .font(.system(size: 13))
                Button("Check Again") { updateManager.resetToIdle() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.40))
            }

        case .available(let version, let url):
            Button {
                updateManager.startDownload(version: version, downloadURL: url)
            } label: {
                Label("Download v\(version)", systemImage: "arrow.down.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

        case .downloaded(let version, let zipURL):
            Button {
                updateManager.installDownloaded(version: version, zipURL: zipURL)
            } label: {
                Label("Install & Relaunch", systemImage: "arrow.clockwise.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(selectedTheme.accent)
        }
    }

    var aboutPanelBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selectedTheme.cardBgColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedTheme.cardBorderColor, lineWidth: 0.9)
            )
    }

    @ViewBuilder
    func aboutColumnTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 15, weight: .bold, design: .monospaced))
            .foregroundStyle(selectedTheme.accent.opacity(0.72))
            .tracking(2.6)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    @ViewBuilder
    func aboutFactRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(selectedTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))

                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
