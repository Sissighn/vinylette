import Foundation

/// Central persistence for user-facing widget settings. SwiftUI, the AppKit
/// menu, and tests all go through the same key and fallback rules, so the
/// call sites cannot drift apart.
struct WidgetSettings {
    static let designKey = "widgetDesign"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var design: WidgetDesign {
        get {
            defaults.string(forKey: Self.designKey)
                .flatMap(WidgetDesign.init(rawValue:)) ?? .classicLabel
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Self.designKey)
        }
    }
}
