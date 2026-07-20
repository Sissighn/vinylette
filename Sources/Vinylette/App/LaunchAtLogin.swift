import AppKit
import ServiceManagement

/// Abstraction over `SMAppService` so menu behavior can be tested without
/// touching the real login-item registry.
protocol LoginItemManaging {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
    func openSystemSettings()
}

/// The real login item backed by `SMAppService.mainApp`.
struct MainAppLoginItem: LoginItemManaging {
    var status: SMAppService.Status { SMAppService.mainApp.status }
    func register() throws { try SMAppService.mainApp.register() }
    func unregister() throws { try SMAppService.mainApp.unregister() }
    func openSystemSettings() { SMAppService.openSystemSettingsLoginItems() }
}

/// Menu-facing behavior of the "Launch at Login" item: how the current status
/// renders, and what a click should do in each state.
struct LaunchAtLogin {
    private let manager: LoginItemManaging

    init(manager: LoginItemManaging = MainAppLoginItem()) {
        self.manager = manager
    }

    var menuState: NSControl.StateValue {
        switch manager.status {
        case .enabled:
            return .on
        case .requiresApproval:
            return .mixed
        case .notRegistered, .notFound:
            return .off
        @unknown default:
            return .off
        }
    }

    func toggle() throws {
        switch manager.status {
        case .enabled:
            try manager.unregister()
        case .requiresApproval:
            manager.openSystemSettings()
        case .notRegistered, .notFound:
            try manager.register()
        @unknown default:
            try manager.register()
        }
    }
}
