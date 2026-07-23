import Foundation

/// The three widget looks selectable from the hover settings menu.
enum WidgetDesign: String, CaseIterable, Identifiable {
    case classicLabel  // printed label with artist & track on the record
    case albumCover  // album cover as the record label
    case sleeve  // record peeking out of the album sleeve

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicLabel: return L10n.Design.classicLabel
        case .albumCover: return L10n.Design.albumCover
        case .sleeve: return L10n.Design.sleeve
        }
    }
}
