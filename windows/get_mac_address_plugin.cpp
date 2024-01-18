#include "get_mac_address_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <iptypes.h>
#include <iphlpapi.h>
#include <iomanip> 
// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#pragma comment(lib, "iphlpapi.lib")

namespace get_mac_address {

// static
void GetMacAddressPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  const auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "get_mac_address",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<GetMacAddressPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

GetMacAddressPlugin::GetMacAddressPlugin() = default;

GetMacAddressPlugin::~GetMacAddressPlugin() = default;

void GetMacAddressPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) const
{
      printf("HandleMethodCall\n");
  if (method_call.method_name() == "getMacAddress") {
    char* pMac = getMAC();
    const std::string macAddress = std::string(pMac);
    free(pMac);
    result->Success(flutter::EncodableValue(macAddress.c_str()));
  } else {
    result->NotImplemented();
  }
}


char* GetMacAddressPlugin::getMAC() const {
    DWORD dwBufLen = sizeof(IP_ADAPTER_INFO);
    char* mac_addr = nullptr;
    auto AdapterInfo = static_cast<IP_ADAPTER_INFO*>(malloc(dwBufLen));

    if (AdapterInfo == nullptr) {
        perror("Error allocating memory needed to call GetAdaptersinfo");
        return nullptr;
    }

    // Make an initial call to GetAdaptersInfo to get the necessary size into the dwBufLen variable
    if (GetAdaptersInfo(AdapterInfo, &dwBufLen) == ERROR_BUFFER_OVERFLOW) {
        free(AdapterInfo);
        AdapterInfo = static_cast<IP_ADAPTER_INFO*>(malloc(dwBufLen));

        if (AdapterInfo == nullptr) {
            perror("Error allocating memory needed to call GetAdaptersinfo");
            return nullptr;
        }
    }

    if (GetAdaptersInfo(AdapterInfo, &dwBufLen) == NO_ERROR) {
        // Contains pointer to current adapter info
        PIP_ADAPTER_INFO pAdapterInfo = AdapterInfo;

        // Create a set to store unique MAC addresses
        std::set<std::string> uniqueMacAddresses;

        do {
            if (pAdapterInfo->Type == MIB_IF_TYPE_ETHERNET) {
                std::ostringstream macAddressStream;
                macAddressStream << std::hex << std::uppercase
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[0]) << ":"
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[1]) << ":"
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[2]) << ":"
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[3]) << ":"
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[4]) << ":"
                                 << std::setw(2) << std::setfill('0') << static_cast<int>(pAdapterInfo->Address[5]);

                // Insert the MAC address into the set
                uniqueMacAddresses.insert(macAddressStream.str());

                printf("Address: %s, mac: %s\n", pAdapterInfo->IpAddressList.IpAddress.String, macAddressStream.str().c_str());
            }

            pAdapterInfo = pAdapterInfo->Next;
        } while (pAdapterInfo);

        // Create a dynamic string to store the unique MAC addresses
        std::string macAddresses;
        for (const auto& uniqueMac : uniqueMacAddresses) {
            macAddresses += uniqueMac;
            macAddresses += ";";
        }

        // Remove the trailing semicolon
        if (!macAddresses.empty()) {
            macAddresses.pop_back();
        }

        // Allocate memory for the final string
        free(mac_addr);  // Free previous memory, if any
        mac_addr = static_cast<char*>(malloc(macAddresses.length() + 1));
        if (mac_addr != nullptr) {
            // Copy the string to the allocated memory using strcpy_s
            strcpy_s(mac_addr, macAddresses.length() + 1, macAddresses.c_str());
        } else {
            perror("Error allocating memory for the final string");
        }
    } else {
        perror("Error calling GetAdaptersInfo");
    }

    // Free the allocated memory
    free(AdapterInfo);

    if (mac_addr == nullptr) {
        // No MAC address found, print a message or handle as needed
        std::cerr << "No MAC address found." << std::endl;
    }

    return mac_addr; // Caller must free.
}

}  // namespace get_mac_address



// Hoặc bạn có thể sử dụng lớp
class AdapterInfo {
public:
    std::string ipAddress;
    std::string macAddress;

    // Các thông tin khác mà bạn muốn thêm
};