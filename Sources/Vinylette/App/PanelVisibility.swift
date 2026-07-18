import Combine

/// Whether the panel is actually visible on screen — false while it is fully
/// covered by other windows or ordered out. Drives pausing the spin animation
/// so the widget does no rendering work nobody can see.
final class PanelVisibility: ObservableObject {
    @Published var isVisible = true
}
