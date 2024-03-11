import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var overlayWindow = OverlayWindow()
  lazy var inspectorWindow = InspectorWindow()

  var isInspectingEnabled: Bool = false {
    didSet {
      inspectorWindow.isInspectingEnabled = isInspectingEnabled
    }
  }

  var tap: CFMachPort!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    inspectorWindow.inspectButtonClicked = {
      self.isInspectingEnabled.toggle()
    }

    inspectorWindow.setContentSize(CGSize(width: 600, height: 800))
    inspectorWindow.setPosition(vertical: .bottom, horizontal: .right)

    inspectorWindow.orderFront(nil)
    
    let trustedCheckOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
    let options = [trustedCheckOptionPrompt: true] as CFDictionary
    if AXIsProcessTrustedWithOptions(options) {
      setup()
    } else {
      waitPermisionGranted {
        self.setup()
      }
    }
  }

  private func setup() {
    let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.mouseMoved.rawValue)
    tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: mask,
      callback: { (proxy, type, event, refcon) in
        if let observer = refcon {
          let this = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()

          switch event.type {
          case .leftMouseDown:
            if this.isInspectingEnabled {
              this.isInspectingEnabled.toggle()
              return nil
            }
          case .mouseMoved:
            this.mouseMoved()
          case .tapDisabledByTimeout:
            this.enableTap()
          default:
            break
          }
        }
        return Unmanaged.passUnretained(event)
      },
      userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    )

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

    enableTap()
  }

  private func enableTap() {
    CGEvent.tapEnable(tap: tap, enable: true)
  }

  private func mouseMoved() {
    guard isInspectingEnabled else {
      return
    }

    let systemWideElement = AXUIElementCreateSystemWide()

    let mouseLocation = carbonScreenPointFromCocoaScreenPoint(NSEvent.mouseLocation)

    var element: AXUIElement?
    let copyElementError = AXUIElementCopyElementAtPosition(
      systemWideElement,
      Float(mouseLocation.x),
      Float(mouseLocation.y),
      &element
    )

    guard let element, copyElementError == .success else {
      return
    }

    var attributeValue: AnyObject?
    let attributeValueError = AXUIElementCopyAttributeValue(
      element,
      "AXFrame" as CFString,
      &attributeValue
    )

    guard let attributeValue, attributeValueError == .success else {
      return
    }

    let value = attributeValue as! AXValue

    var rect = CGRect()
    guard AXValueGetValue(value, .cgRect, &rect) else {
      return
    }

    var origin = cocoaScreenPointFromCarbonScreenPoint(rect.origin)
    origin.y -= rect.height

    overlayWindow.setFrameOrigin(origin)
    overlayWindow.setContentSize(rect.size)

    overlayWindow.orderFront(nil)

    inspectorWindow.elementTitle = title(of: element)
    inspectorWindow.attributedText = inspect(element: element)
  }

  private func waitPermisionGranted(completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      if AXIsProcessTrusted() {
        completion()
      } else {
        self.waitPermisionGranted(completion: completion)
      }
    }
  }
}
