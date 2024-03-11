import Cocoa
import Carbon
import VisionKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  lazy var overlayWindow = OverlayWindow()
  lazy var textWindow = TextWindow()

  var isCapturingEnabled: Bool = false {
    didSet {
      textWindow.isCapturingEnabled = isCapturingEnabled
    }
  }

  var tap: CFMachPort!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.image = NSImage(named: "translate")

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Quit Comic Translator", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu

    textWindow.inspectButtonClicked = {
      self.isCapturingEnabled.toggle()
    }

    textWindow.setContentSize(CGSize(width: 320, height: 600))
    textWindow.setPosition(vertical: .bottom, horizontal: .right)
    textWindow.orderFront(nil)

    let trustedCheckOptionPrompt = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
    let options = [trustedCheckOptionPrompt: true] as CFDictionary
    if AXIsProcessTrustedWithOptions(options) {
      setup()
    } else {
      waitAccessibilityPermisionGranted {
        self.setup()
      }
    }
  }

  private func setup() {
    guard CGPreflightScreenCaptureAccess() else {
      guard CGRequestScreenCaptureAccess() else {
        print("Screen & System Audio Recording Permission is not granted!")
        return
      }
      return
    }

    let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.mouseMoved.rawValue) | (1 << CGEventType.keyDown.rawValue)
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
            return this.leftMouseDown(event: event)
          case .mouseMoved:
            return this.mouseMoved(event: event)
          case .keyDown:
            return this.keyDown(event: event)
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

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return false
  }

  private func leftMouseDown(event: CGEvent) -> Unmanaged<CGEvent>? {
    if isCapturingEnabled {
      isCapturingEnabled.toggle()

      let rect = overlayWindow.carbonRect
      overlayWindow.orderOut(nil)
      RunLoop.current.run(until: Date())

      textWindow.isLoading = true

      let analyzer = ImageAnalyzer()
      Task {
        guard let image = try await captureScreen(rect: rect) else {
          return
        }
     // Uncomment if you try to use CGWindowListCreateImage instead of ScreenCaptureKit
     // guard let image = captureScreen(rect: rect) else {
     //   return nil
     // }

        let configuration = ImageAnalyzer.Configuration([.text])

        let analysis = try? await analyzer.analyze(image, orientation: .up, configuration: configuration)

        guard let transcript = analysis?.transcript else {
          return
        }

        print(transcript)
        let command = """
          \(transcript)

          The above text is a line from a comic book. Please translate it into English. The result should be returned so that the corresponding Japanese and English sentences appear alternately for each line. The original Japanese sentence must not be missing.
          """

        sendFakeRequest(command: command) { (result) in
          Task {
            await MainActor.run {
              self.textWindow.text = result
              self.textWindow.isLoading = false
            }
          }
        }
     // Uncomment if you have OpenAI API key and want to use real request
     // sendOpenAIRequest(command: command) { (result) in
     //   Task {
     //     await MainActor.run {
     //       self.textWindow.isLoading = false
     //
     //       if let result {
     //         self.textWindow.text = result
     //       } else {
     //         self.textWindow.text = "Something went wrong."
     //       }
     //     }
     //   }
     // }
      }

      return nil
    } else {
      return Unmanaged.passUnretained(event)
    }
  }

  private func mouseMoved(event: CGEvent) -> Unmanaged<CGEvent>? {
    guard isCapturingEnabled else {
      return Unmanaged.passUnretained(event)
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
      return Unmanaged.passUnretained(event)
    }

    var attributeValue: AnyObject?
    let attributeValueError = AXUIElementCopyAttributeValue(
      element,
      "AXFrame" as CFString,
      &attributeValue
    )

    guard let attributeValue, attributeValueError == .success else {
      return Unmanaged.passUnretained(event)
    }

    let value = attributeValue as! AXValue

    var rect = CGRect()
    guard AXValueGetValue(value, .cgRect, &rect) else {
      return Unmanaged.passUnretained(event)
    }

    overlayWindow.carbonRect = rect

    var origin = cocoaScreenPointFromCarbonScreenPoint(rect.origin)
    origin.y -= rect.height

    overlayWindow.setFrameOrigin(origin)
    overlayWindow.setContentSize(rect.size)

    overlayWindow.orderFront(nil)

    return Unmanaged.passUnretained(event)
  }

  private func keyDown(event: CGEvent) -> Unmanaged<CGEvent>? {
    if let nsEvent = NSEvent(cgEvent: event), nsEvent.keyCode == kVK_Escape {
      isCapturingEnabled.toggle()
      overlayWindow.close()
      return nil
    }

    return Unmanaged.passUnretained(event)
  }

  private func enableTap() {
    CGEvent.tapEnable(tap: tap, enable: true)
  }

  private func waitAccessibilityPermisionGranted(completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      if AXIsProcessTrusted() {
        completion()
      } else {
        self.waitAccessibilityPermisionGranted(completion: completion)
      }
    }
  }
}
