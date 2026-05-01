import Foundation
import ServiceManagement

enum LaunchAtLoginError: Error, LocalizedError {
    case unsupported

    var errorDescription: String? {
        switch self {
        case .unsupported: "Launch at login is not supported on this macOS version."
        }
    }
}

final class LaunchAtLoginService {
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    func setEnabled(_ isEnabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } else {
            throw LaunchAtLoginError.unsupported
        }
    }
}
