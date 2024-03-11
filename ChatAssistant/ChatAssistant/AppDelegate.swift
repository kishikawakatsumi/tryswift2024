import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  lazy var assistantWindow = AssistantWindow()

  var selectedText = ""

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.image = NSImage(named: "assistant")

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Quit Chat Assistant", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu

    assistantWindow.sendButtonClicked = {
      self.assistantWindow.isLoading = true

      let command = """
          \(self.selectedText)

          \(self.assistantWindow.prompt)
          """

      print(command)

      sendFakeRequest(command: command) { (result) in
        self.assistantWindow.isLoading = false
        self.assistantWindow.text = result
      }
   // Uncomment if you have OpenAI API key and want to use real request
   // sendOpenAIRequest(command: command) { (result) in
   //   DispatchQueue.main.async {
   //     self.assistantWindow.isLoading = false
   //
   //     if let result {
   //       let codeBlock = extractCodeBlock(from: result)
   //       if !codeBlock.isEmpty {
   //         self.assistantWindow.text = codeBlock
   //       } else {
   //         self.assistantWindow.text = result
   //       }
   //     } else {
   //       self.assistantWindow.text = "Something went wrong."
   //     }
   //   }
   // }
    }

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
    NSEvent.addGlobalMonitorForEvents(
      matching: [.keyDown]
    ) { (event) in
      switch event.type {
      case .keyDown:
        guard event.modifierFlags.contains([.command, .control]) && event.keyCode == kVK_ANSI_A else {
          return
        }

        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?

        let focusedElementError = AXUIElementCopyAttributeValue(
          systemWideElement,
          kAXFocusedUIElementAttribute as CFString,
          &focusedElement
        )
        guard let focusedElement, focusedElementError == .success else {
          return
        }

        var selectedTextValue: AnyObject?
        let selectedTextValueError = AXUIElementCopyAttributeValue(
          focusedElement as! AXUIElement,
          kAXSelectedTextAttribute as CFString,
          &selectedTextValue
        )
        if let selectedTextValue, selectedTextValueError == .success {
          self.selectedText = "\(selectedTextValue)"

          var selectedTextRangeValue: AnyObject?
          let selectedTextRangeValueError = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedTextRangeValue
          )
          guard let selectedTextRangeValue, selectedTextRangeValueError == .success else {
            return
          }

          var boundsForRangeValue: AnyObject?
          let boundsForRangeValueError = AXUIElementCopyParameterizedAttributeValue(
            focusedElement as! AXUIElement,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            selectedTextRangeValue,
            &boundsForRangeValue
          )
          guard let boundsForRangeValue, boundsForRangeValueError == .success else {
            return
          }

          var frame = CGRect()
          guard AXValueGetValue(boundsForRangeValue as! AXValue, .cgRect, &frame) else {
            return
          }

          self.showAssistantWindow(at: frame)
        } else {
          var selectedTextMarkerRangeValue: AnyObject?
          let selectedTextMarkerRangeValueError = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            "AXSelectedTextMarkerRange" as CFString,
            &selectedTextMarkerRangeValue
          )

          guard let selectedTextMarkerRangeValue, selectedTextMarkerRangeValueError == .success else {
            return
          }

          var stringForTextMarkerRangeValue: AnyObject?
          let stringForTextMarkerRangeValueError = AXUIElementCopyParameterizedAttributeValue(
            focusedElement as! AXUIElement,
            "AXStringForTextMarkerRange" as CFString,
            selectedTextMarkerRangeValue,
            &stringForTextMarkerRangeValue
          )

          guard let stringForTextMarkerRangeValue, stringForTextMarkerRangeValueError == .success else {
            return
          }

          self.selectedText = "\(stringForTextMarkerRangeValue)"

          var boundsForTextMarkerRangeValue: AnyObject?
          let boundsForTextMarkerRangeValueError = AXUIElementCopyParameterizedAttributeValue(
            focusedElement as! AXUIElement,
            "AXBoundsForTextMarkerRange" as CFString,
            selectedTextMarkerRangeValue,
            &boundsForTextMarkerRangeValue
          )
          guard let boundsForTextMarkerRangeValue, boundsForTextMarkerRangeValueError == .success else {
            return
          }

          var frame = CGRect()
          guard AXValueGetValue(boundsForTextMarkerRangeValue as! AXValue, .cgRect, &frame) else {
            return
          }

          self.showAssistantWindow(at: frame)
        }

        print(self.selectedText)
      default:
        break
      }
    }

    NotificationCenter.default.addObserver(self, selector: #selector(closeFloatingPanel), name: NSWindow.didResignKeyNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(closeFloatingPanel), name: NSWindow.didResignMainNotification, object: nil)
  }

  private func showAssistantWindow(at rect: CGRect) {
    var origin = carbonScreenPointFromCocoaScreenPoint(rect.origin)
    origin.x += assistantWindow.contentView!.bounds.width
    origin.y -= assistantWindow.contentView!.bounds.height

    assistantWindow.text = ""
    assistantWindow.setFrameOrigin(origin)

    assistantWindow.orderFront(nil)
    assistantWindow.makeKey()

    NSApp.activate(ignoringOtherApps: true)
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

  @objc func closeFloatingPanel() {
    assistantWindow.close()
  }
}
