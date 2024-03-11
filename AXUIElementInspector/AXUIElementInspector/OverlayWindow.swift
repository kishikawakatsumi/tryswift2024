import AppKit

class OverlayWindow: NSPanel {
  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.closable, .fullSizeContentView, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    isFloatingPanel = true
    level = .floating

    collectionBehavior.insert(.fullScreenAuxiliary)

    titleVisibility = .hidden
    titlebarAppearsTransparent = true

    isMovableByWindowBackground = false

    isReleasedWhenClosed = false

    hidesOnDeactivate = false

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    ignoresMouseEvents = true

    isOpaque = false
    backgroundColor = .clear

    contentView = OverlayContentView()
  }

  override var canBecomeKey: Bool {
    return false
  }

  override var canBecomeMain: Bool {
    return false
  }
}

class OverlayContentView: NSView {
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    let backgroundColor = NSColor(red: 0.7, green: 0.85, blue: 1, alpha: 0.5)
    backgroundColor.setFill()
    dirtyRect.fill()

    let borderColor = NSColor(red: 0, green: 0.53, blue: 0.87, alpha: 1)
    let borderPath = NSBezierPath(rect: dirtyRect)
    borderPath.lineWidth = 2
    borderColor.setStroke()
    borderPath.stroke()
  }
}
