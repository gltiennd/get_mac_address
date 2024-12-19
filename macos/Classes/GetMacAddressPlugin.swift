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
        case "getMacAddress":
            guard let macAddresses = getMacAddresses() else {
                result(FlutterError(code: "load_failure", message: "macOS MAC address load failure", details: nil))
                return
            }
            result(macAddresses.joined(separator: ";"))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // Tìm tất cả các giao diện mạng (bao gồm cả Ethernet và Wi-Fi)
    func FindNetworkInterfaces() -> io_iterator_t? {
        let matchingDictUM = IOServiceMatching("IONetworkInterface")
        if matchingDictUM == nil {
            return nil
        }

        let matchingDict = matchingDictUM! as NSMutableDictionary
        var matchingServices: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
            return nil
        }

        return matchingServices
    }

    // Lấy tất cả các địa chỉ MAC của các giao diện mạng
    func GetMACAddresses(_ intfIterator: io_iterator_t) -> [String]? {
        var macAddresses: [String] = []

        var intfService = IOIteratorNext(intfIterator)
        while intfService != 0 {
            var controllerService: io_object_t = 0
            if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS {
                let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
                if dataUM != nil {
                    let data = (dataUM!.takeRetainedValue() as! CFData) as Data
                    let macAddress = data.map { String(format: "%02x", $0) }.joined(separator: ":")
                    macAddresses.append(macAddress)
                }
                IOObjectRelease(controllerService)
            }

            IOObjectRelease(intfService)
            intfService = IOIteratorNext(intfIterator)
        }

        return macAddresses.isEmpty ? nil : macAddresses
    }

    // Lấy tất cả các địa chỉ MAC của các giao diện mạng
    func getMacAddresses() -> [String]? {
        var macAddressesAsString: [String] = []
        if let intfIterator = FindNetworkInterfaces() {
            if let macAddresses = GetMACAddresses(intfIterator) {
                macAddressesAsString = macAddresses
                print(macAddressesAsString)  // In ra tất cả địa chỉ MAC
            }

            IOObjectRelease(intfIterator)
        }
        return macAddressesAsString.isEmpty ? nil : macAddressesAsString
    }
}
