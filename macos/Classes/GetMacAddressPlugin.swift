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
        result(FlutterError.init(code: "load_failure", message: "macOS MAC address load failure", details: nil))
        return
      }
      result(macAddress)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func getAllMACAddresses() -> String? {
    let task = Process()
    task.launchPath = "/sbin/ifconfig"
    task.arguments = ["en0"]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        // Tìm dòng chứa "ether" để lấy địa chỉ MAC
        if let line = output.components(separatedBy: "\n").first(where: { $0.contains("ether") }) {
            // Tách địa chỉ MAC từ dòng tìm được
            return extractMACAddress(from: line)
        }
    }
    return nil
  }

  func extractMACAddress(from line: String) -> String? {
    let components = line.components(separatedBy: " ")
    if let index = components.firstIndex(of: "ether"), components.count > index + 1 {
        return components[index + 1]
    }
    return nil
  }
}
