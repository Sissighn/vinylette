import Foundation

/// Typed access to the strings compiled from `Localizable.xcstrings`.
/// Keys exist exactly once, here — call sites cannot misspell them, and the
/// localization tests verify every key against the catalog. Keeping AppKit
/// and SwiftUI on the same lookup path avoids mixed languages.
enum L10n {
    enum Accessibility {
        static let design = text("accessibility.design")
        static let openAutomationSettings = text("accessibility.openAutomationSettings")
        static let pause = text("accessibility.pause")
        static let play = text("accessibility.play")
    }

    enum Design {
        static let albumCover = text("design.albumCover")
        static let classicLabel = text("design.classicLabel")
        static let sleeve = text("design.sleeve")
    }

    enum Menu {
        static let design = text("menu.design")
        static let launchAtLogin = text("menu.launchAtLogin")
        static let noTrack = text("menu.noTrack")
        static let quit = text("menu.quit")
        static let toggleWidget = text("menu.toggleWidget")
    }

    enum Permission {
        static let allow = text("permission.allow")
        static let missing = text("permission.missing")
    }

    enum ServiceError {
        static let message = text("service.error.message")
        static let title = text("service.error.title")
    }

    enum Spotify {
        static let unavailable = text("spotify.unavailable")
    }

    enum SpotifyError {
        static let artwork = text("spotify.error.artwork")
        static let command = text("spotify.error.command")
        static let dismiss = text("spotify.error.dismiss")
        static let state = text("spotify.error.state")
    }

    private static let resourceBundle: Bundle = {
        if let resourceURL = Bundle.main.resourceURL?
            .appendingPathComponent("Vinylette_Vinylette.bundle"),
            let bundledResources = Bundle(url: resourceURL)
        {
            return bundledResources
        }
        return .module
    }()

    private static func text(_ key: String) -> String {
        resourceBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
