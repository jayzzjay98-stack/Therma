import Foundation

enum MonitorDisplayMode: String, CaseIterable, Identifiable {
    case memory
    case cpu
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory: return "RAM"
        case .cpu:    return "CPU"
        case .both:   return "Both"
        }
    }

    var description: String {
        switch self {
        case .memory: return "Show only the RAM item in the menu bar"
        case .cpu:    return "Show only the CPU temperature item in the menu bar"
        case .both:   return "Show separate RAM and CPU items in the menu bar"
        }
    }

    var showsMemory: Bool {
        self == .memory || self == .both
    }

    var showsCPU: Bool {
        self == .cpu || self == .both
    }
}
