import Foundation
import IOKit

var iterator: io_iterator_t = 0
guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOService"), &iterator) == KERN_SUCCESS else { exit(1) }

while let svc = IOIteratorNext(iterator) as io_object_t?, svc != 0 {
    defer { IOObjectRelease(svc) }
    guard let unmanaged = IORegistryEntryCreateCFProperty(svc, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0) else { continue }
    
    var name = [CChar](repeating: 0, count: 128)
    IORegistryEntryGetName(svc, &name)
    let svcName = String(cString: name)
    
    if svcName.lowercased().contains("ane") || svcName.lowercased().contains("neural") {
       print("FOUND ANE: \(svcName)")
    }
}
