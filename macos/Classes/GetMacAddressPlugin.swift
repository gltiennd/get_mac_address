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
    guard let macAddress = getAllMACAddresses() else {
        result(FlutterError.init(code: "load failure", message: "macOS mac address load failure",details: nil))
        return
    }
    result(macAddress)
    default:
      result(FlutterMethodNotImplemented)
    }
  }


//   func FindEthernetInterfaces() -> io_iterator_t? {

//       let matchingDictUM = IOServiceMatching("IOEthernetInterface");
//       // Note that another option here would be:
//       // matchingDict = IOBSDMatching("en0");
//       // but en0: isn't necessarily the primary interface, especially on systems with multiple Ethernet ports.

//       if matchingDictUM == nil {
//           return nil
//       }

//       let matchingDict = matchingDictUM! as NSMutableDictionary
//       matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]

//       var matchingServices : io_iterator_t = 0
//       if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
//           return nil
//       }

//       return matchingServices
//   }

  // Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
  // If no interfaces are found the MAC address is set to an empty string.
  // In this sample the iterator should contain just the primary interface.
  func GetMACAddress(_ intfIterator : io_iterator_t) -> [UInt8]? {

      var macAddress : [UInt8]?

      var intfService = IOIteratorNext(intfIterator)
      while intfService != 0 {

          var controllerService : io_object_t = 0
          if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS {

              let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
              if dataUM != nil {
                  let data = (dataUM!.takeRetainedValue() as! CFData) as Data
                  macAddress = [0, 0, 0, 0, 0, 0]
                  data.copyBytes(to: &macAddress!, count: macAddress!.count)
              }
              IOObjectRelease(controllerService)
          }

          IOObjectRelease(intfService)
          intfService = IOIteratorNext(intfIterator)
      }

      return macAddress
  }


func getAllMACAddresses() -> String? {
    var macAddresses: [String] = []

    let task = Process()
    task.launchPath = "/usr/sbin/arp"
    task.arguments = ["-a"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if let macAddress = extractMACAddress(from: line) {
                macAddresses.append(macAddress)
            }
        }
    }

    return macAddresses.joined(separator: ";")
}




func extractMACAddress(from line: String) -> String? {
    let components = line.components(separatedBy: " ")
    if components.count >= 4 {
        return components[3]
    }
    return nil
}


//   func getMacAddress() -> String? {
//       let matchingDictUM = IOServiceMatching("IOEthernetInterface")

//     if matchingDictUM == nil {
//         return "no"
//     }

//     let matchingDict = matchingDictUM! as NSMutableDictionary
//     matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]

//     var matchingServices: io_iterator_t = 0
//     if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
//         return "yes"
//     }

//     var interfaceCount: Int = 0
//     var intfService = IOIteratorNext(matchingServices)
//     while intfService != 0 {
//         interfaceCount += 1
//         IOObjectRelease(intfService)
//         intfService = IOIteratorNext(matchingServices)
//     }

//     IOObjectRelease(matchingServices)

//     return "Integer Value: \(interfaceCount)"
//   }


}
