import AppKit
import ServiceManagement
import XCTest

@testable import Vinylette

final class WidgetSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "vinylette-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultDesignIsClassicLabel() {
        let settings = WidgetSettings(defaults: defaults)

        XCTAssertEqual(settings.design, .classicLabel)
    }

    func testDesignRoundTripsThroughPersistence() {
        let settings = WidgetSettings(defaults: defaults)

        settings.design = .sleeve

        XCTAssertEqual(WidgetSettings(defaults: defaults).design, .sleeve)
        XCTAssertEqual(
            defaults.string(forKey: WidgetSettings.designKey),
            WidgetDesign.sleeve.rawValue)
    }

    func testUnknownStoredValueFallsBackToClassicLabel() {
        defaults.set("disco-ball", forKey: WidgetSettings.designKey)

        XCTAssertEqual(WidgetSettings(defaults: defaults).design, .classicLabel)
    }

    func testEveryDesignSurvivesTheRoundTrip() {
        let settings = WidgetSettings(defaults: defaults)

        for design in WidgetDesign.allCases {
            settings.design = design
            XCTAssertEqual(settings.design, design)
        }
    }
}

final class LaunchAtLoginTests: XCTestCase {
    private final class FakeLoginItem: LoginItemManaging {
        var status: SMAppService.Status
        var registered = 0
        var unregistered = 0
        var openedSettings = 0
        var nextError: Error?

        init(status: SMAppService.Status) {
            self.status = status
        }

        func register() throws {
            if let nextError { throw nextError }
            registered += 1
            status = .enabled
        }

        func unregister() throws {
            if let nextError { throw nextError }
            unregistered += 1
            status = .notRegistered
        }

        func openSystemSettings() {
            openedSettings += 1
        }
    }

    func testToggleRegistersWhenNotRegistered() throws {
        let item = FakeLoginItem(status: .notRegistered)

        try LaunchAtLogin(manager: item).toggle()

        XCTAssertEqual(item.registered, 1)
        XCTAssertEqual(item.status, .enabled)
    }

    func testToggleUnregistersWhenEnabled() throws {
        let item = FakeLoginItem(status: .enabled)

        try LaunchAtLogin(manager: item).toggle()

        XCTAssertEqual(item.unregistered, 1)
        XCTAssertEqual(item.status, .notRegistered)
    }

    func testToggleOpensSystemSettingsWhenApprovalIsPending() throws {
        let item = FakeLoginItem(status: .requiresApproval)

        try LaunchAtLogin(manager: item).toggle()

        XCTAssertEqual(item.openedSettings, 1)
        XCTAssertEqual(item.registered, 0)
        XCTAssertEqual(item.unregistered, 0)
    }

    func testToggleSurfacesServiceErrors() {
        let item = FakeLoginItem(status: .notRegistered)
        item.nextError = CocoaError(.fileNoSuchFile)

        XCTAssertThrowsError(try LaunchAtLogin(manager: item).toggle())
    }

    func testMenuStateReflectsServiceStatus() {
        XCTAssertEqual(LaunchAtLogin(manager: FakeLoginItem(status: .enabled)).menuState, .on)
        XCTAssertEqual(
            LaunchAtLogin(manager: FakeLoginItem(status: .requiresApproval)).menuState,
            .mixed)
        XCTAssertEqual(
            LaunchAtLogin(manager: FakeLoginItem(status: .notRegistered)).menuState,
            .off)
        XCTAssertEqual(LaunchAtLogin(manager: FakeLoginItem(status: .notFound)).menuState, .off)
    }
}
