import AppKit

class TextWindow: NSPanel {
  var isLoading = false {
    didSet {
      if isLoading {
        progressIndicator.startAnimation(nil)
        textView.isHidden = true
      } else {
        progressIndicator.stopAnimation(nil)
        textView.isHidden = false
      }
    }
  }

  var text: String {
    get {
      documentView.string
    }
    set {
      documentView.string = newValue
    }
  }

  var isCapturingEnabled: Bool = false {
    didSet {
      inspectButton.state = isCapturingEnabled ? .on : .off
    }
  }

  var inspectButtonClicked: () -> () = {}

  private let inspectButton = NSButton(image: NSImage(named: "crosshair")!, target: nil, action: nil)
  private let progressIndicator = NSProgressIndicator()

  private let textView = NSTextView.scrollableTextView()
  private var documentView: NSTextView {
    textView.documentView as! NSTextView
  }

  init() {
    super.init(
      contentRect: .zero,
      styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    isFloatingPanel = true
    level = .floating

    collectionBehavior.insert(.fullScreenAuxiliary)

    let rootView = NSView()
    contentView = rootView

    inspectButton.translatesAutoresizingMaskIntoConstraints = false
    inspectButton.setContentHuggingPriority(.required, for: .horizontal)
    inspectButton.bezelStyle = .flexiblePush
    inspectButton.imageScaling = .scaleNone
    inspectButton.setButtonType(.onOff)

    inspectButton.target = self
    inspectButton.action = #selector(inspectButtonAction)

    rootView.addSubview(inspectButton)

    progressIndicator.translatesAutoresizingMaskIntoConstraints = false
    progressIndicator.style = .spinning
    progressIndicator.controlSize = .regular
    progressIndicator.isDisplayedWhenStopped = false
    rootView.addSubview(progressIndicator)

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isHidden = true
    documentView.textContainerInset = NSSize(width: 8, height: 8)
    documentView.font = .systemFont(ofSize: 24)
    rootView.addSubview(textView)

    NSLayoutConstraint.activate([
      inspectButton.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 12),
      inspectButton.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -12),
      inspectButton.widthAnchor.constraint(equalToConstant: 32),
      inspectButton.heightAnchor.constraint(equalToConstant: 30),

      progressIndicator.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
      progressIndicator.centerYAnchor.constraint(equalTo: rootView.centerYAnchor),

      textView.topAnchor.constraint(equalTo: inspectButton.bottomAnchor, constant: 20),
      textView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 0),
      textView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: 0),
      textView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: 0),
    ])
  }

  override var canBecomeKey: Bool {
    return true
  }

  override var canBecomeMain: Bool {
    return true
  }

  @objc
  func inspectButtonAction() {
    inspectButtonClicked()
  }
}
