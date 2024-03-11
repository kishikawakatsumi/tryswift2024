import AppKit

class InspectorWindow: NSPanel {
  var elementTitle: String {
    get {
      elementTitleLabel.stringValue
    }
    set {
      elementTitleLabel.stringValue = newValue
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

  var attributedText: NSAttributedString {
    get {
      documentView.attributedString()
    }
    set {
      documentView.textStorage?.setAttributedString(newValue)
    }
  }

  var isInspectingEnabled: Bool = false {
    didSet {
      inspectButton.state = isInspectingEnabled ? .on : .off
    }
  }

  var inspectButtonClicked: () -> () = {}

  private let inspectedElementSectionLabel = NSTextField(labelWithString: "Inspected Element:")
  private let elementTitleLabel = NSTextField(labelWithString: "")
  private let inspectButton = NSButton(image: NSImage(named: "crosshair")!, target: nil, action: nil)

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

    inspectedElementSectionLabel.translatesAutoresizingMaskIntoConstraints = false
    inspectedElementSectionLabel.font = NSFont.controlContentFont(ofSize: 12)
    inspectedElementSectionLabel.textColor = NSColor.secondaryLabelColor
    rootView.addSubview(inspectedElementSectionLabel)

    elementTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    elementTitleLabel.font = NSFont.boldSystemFont(ofSize: 12)
    rootView.addSubview(elementTitleLabel)

    inspectButton.translatesAutoresizingMaskIntoConstraints = false
    inspectButton.setContentHuggingPriority(.required, for: .horizontal)
    inspectButton.bezelStyle = .flexiblePush
    inspectButton.imageScaling = .scaleNone
    inspectButton.setButtonType(.onOff)

    inspectButton.target = self
    inspectButton.action = #selector(inspectButtonAction)

    rootView.addSubview(inspectButton)

    let separator = NSBox()
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.boxType = .separator
    rootView.addSubview(separator)

    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.scrollerStyle = .overlay

    documentView.drawsBackground = false
    documentView.isEditable = false
    documentView.isSelectable = true
    documentView.textContainerInset = NSSize(width: 8, height: 0)
    documentView.textContainer?.widthTracksTextView = false

    rootView.addSubview(textView)

    NSLayoutConstraint.activate([
      inspectedElementSectionLabel.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 12),
      inspectedElementSectionLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 12),
      inspectedElementSectionLabel.trailingAnchor.constraint(equalTo: inspectButton.leadingAnchor, constant: -12),

      elementTitleLabel.topAnchor.constraint(equalTo: inspectedElementSectionLabel.bottomAnchor, constant: 2),
      elementTitleLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 12),
      elementTitleLabel.trailingAnchor.constraint(equalTo: inspectButton.leadingAnchor, constant: -8),

      inspectButton.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 12),
      inspectButton.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -12),
      inspectButton.widthAnchor.constraint(equalToConstant: 32),
      inspectButton.heightAnchor.constraint(equalToConstant: 30),

      separator.topAnchor.constraint(equalTo: elementTitleLabel.bottomAnchor, constant: 12),
      separator.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 12),
      separator.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -12),

      textView.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 10),
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
