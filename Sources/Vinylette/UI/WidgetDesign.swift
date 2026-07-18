import Foundation

/// The three widget looks selectable from the hover settings menu.
enum WidgetDesign: String, CaseIterable, Identifiable {
    case classicLabel   // printed label with artist & track on the record
    case albumCover     // album cover as the record label
    case sleeve         // record peeking out of the album sleeve

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicLabel: return "Klassisches Label"
        case .albumCover: return "Album-Cover"
        case .sleeve: return "Cover & Platte"
        }
    }
}
