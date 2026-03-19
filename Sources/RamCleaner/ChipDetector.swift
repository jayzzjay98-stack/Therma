import Darwin

// MARK: - Chip Detector
// Single Responsibility: detect the Mac's processor name from sysctl.

enum ChipDetector {

    // MARK: - Apple Silicon model → chip name mapping
    // Source: Apple's published Mac identifier list.

    private static let modelPrefixMap: [(prefix: String, chip: String)] = [
        ("Mac12,", "Apple M1"),
        ("Mac13,", "Apple M1"),   // Mac13,1–4 = MacBook Pro 14/16 M1 Pro/Max, Mac Studio M1 Max/Ultra
        ("Mac14,", "Apple M2"),
        ("Mac15,", "Apple M3"),
        ("Mac16,", "Apple M4"),
    ]

    // MARK: - Public API

    /// Returns the processor name string, e.g. "Apple M3" or an Intel brand string.
    static func detect() -> String {
        guard let model = readSysctlString("hw.model") else {
            return "Unknown"
        }

        for entry in modelPrefixMap where model.hasPrefix(entry.prefix) {
            return entry.chip
        }

        // Fallback: Intel brand string
        if let brand = readSysctlString("machdep.cpu.brand_string"), !brand.isEmpty {
            return brand
        }

        return "Apple Silicon (\(model))"
    }

    // MARK: - Private Helpers

    private static func readSysctlString(_ key: String) -> String? {
        var size: Int = 0
        guard sysctlbyname(key, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(key, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }
}
