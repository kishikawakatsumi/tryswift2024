import AppKit

class LoadingWindow: NSPanel {
  var isLoading: Bool = false {
    didSet {
      if isLoading {
        progressIndicator.startAnimation(nil)
      } else {
        progressIndicator.stopAnimation(false)
      }
    }
  }

  private let progressIndicator = NSProgressIndicator()

  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    isFloatingPanel = true
    level = .floating

    collectionBehavior.insert(.fullScreenAuxiliary)

    titleVisibility = .hidden
    titlebarAppearsTransparent = true

    isMovableByWindowBackground = true

    isReleasedWhenClosed = false

    hidesOnDeactivate = false

    standardWindowButton(.closeButton)?.isHidden = true
    standardWindowButton(.miniaturizeButton)?.isHidden = true
    standardWindowButton(.zoomButton)?.isHidden = true

    let rootView = NSView()

    progressIndicator.translatesAutoresizingMaskIntoConstraints = false
    progressIndicator.style = .spinning

    rootView.addSubview(progressIndicator)

    NSLayoutConstraint.activate([
      progressIndicator.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 20),
      progressIndicator.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
      progressIndicator.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
      progressIndicator.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -20),
    ])

    contentView = rootView
  }

  override var canBecomeKey: Bool {
    return true
  }

  override var canBecomeMain: Bool {
    return true
  }
}
