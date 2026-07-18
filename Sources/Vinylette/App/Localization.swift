import Foundation

/// Typed access point for strings compiled from `Localizable.xcstrings`.
/// Keeping AppKit and SwiftUI on the same lookup path avoids mixed languages.
enum L10n {
    private static let resourceBundle: Bundle = {
        if let resourceURL = Bundle.main.resourceURL?
            .appendingPathComponent("Vinylette_Vinylette.bundle"),
           let bundledResources = Bundle(url: resourceURL) {
            return bundledResources
        }
        return .module
    }()

    static func text(_ key: String) -> String {
        resourceBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
