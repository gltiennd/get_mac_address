import Cocoa
import FlutterMacOS

public class GetMacAddressPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "get_mac_address", binaryMessenger: registrar.messenger)
        let instance = GetMacAddressPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getMacAddresses":
            guard let macAddresses = getMacAddresses() else {
                result(FlutterError.init(code: "load failure", message: "macOS mac addresses load failure", details: nil))
                return
            }
            result(macAddresses)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func FindEthernetInterfaces() -> [io_iterator_t]? {
        var matchingServices: [io_iterator_t] = []
        let matchingDictUM = IOServiceMatching("IOEthernetInterface")

        if matchingDictUM == nil {
            return nil
        }

        let matchingDict = matchingDictUM! as NSMutableDictionary
        matchingDict["IOPropertyMatch"] = ["IOPrimaryInterface": true]

        var matchingService: io_iterator_t = 0
        while IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingService) == KERN_SUCCESS {
            matchingServices.append(matchingService)
            matchingService = 0
        }

        return matchingServices.isEmpty ? nil : matchingServices
    }

    func GetMACAddresses(_ intfIterators: [io_iterator_t]) -> [String] {
        var macAddresses: [String] = []

        for intfIterator in intfIterators {
            var intfService = IOIteratorNext(intfIterator)
            while intfService != 0 {
                var controllerService: io_object_t = 0
                if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS {
                    let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
                    if dataUM != nil {
                        let data = (dataUM!.takeRetainedValue() as! CFData) as Data
                        let macAddress = data.map { String(format: "%02x", $0) }.joined(separator: ":")
                        macAddresses.append(macAddress)
                        print("Address: \(macAddress)")
                    }
                    IOObjectRelease(controllerService)
                }
                IOObjectRelease(intfService)
                intfService = IOIteratorNext(intfIterator)
            }
        }

        return macAddresses
    }

    func getMacAddresses() -> String? {
        var macAddresses: [String] = []

        if let intfIterators = FindEthernetInterfaces() {
            macAddresses = GetMACAddresses(intfIterators)
            for intfIterator in intfIterators {
                IOObjectRelease(intfIterator)
            }
        }

        return macAddresses.isEmpty ? nil : macAddresses.joined(separator: ";")
    }
}
