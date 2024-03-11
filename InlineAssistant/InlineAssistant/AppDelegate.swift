import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  lazy var loadingWindow = LoadingWindow()

  var observers = [AXObserver]()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.image = NSImage(named: "assistant")

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Quit Chat Assistant", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu

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
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.TextEdit").first else {
      return
    }

    let appElement = AXUIElementCreateApplication(app.processIdentifier)

    var observer: AXObserver?
    let observerCallback: AXObserverCallback = { (observer, element, notification, userData) in
      let this = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()

      var identifierValue: AnyObject?

      let identifierValueError = AXUIElementCopyAttributeValue(
        element,
        kAXIdentifierAttribute as CFString,
        &identifierValue
      )

      guard let identifierValue = identifierValue as? String, identifierValueError == .success else {
        return
      }

      guard identifierValue == "First Text View" else {
        return
      }

      var valueValue: AnyObject?

      let valueValueError = AXUIElementCopyAttributeValue(
        element,
        kAXValueAttribute as CFString,
        &valueValue
      )

      guard let valueValue = valueValue as? String, valueValueError == .success else {
        return
      }

      guard !valueValue.isEmpty else {
        return
      }

      var selectedTextRangeValue: AnyObject?

      let selectedTextRangeValueError = AXUIElementCopyAttributeValue(
        element,
        kAXSelectedTextRangeAttribute as CFString,
        &selectedTextRangeValue
      )

      guard let selectedTextRangeValue, selectedTextRangeValueError == .success else {
        return
      }

      var textRange = CFRange()
      guard AXValueGetValue(selectedTextRangeValue as! AXValue, .cfRange, &textRange) else {
        return
      }

      guard textRange.location > 0 && textRange.length == 0 else {
        return
      }

      var previousCharRange = CFRangeMake(textRange.location - 1, 1)

      let previousCharRangeValue = AXValueCreate(.cfRange, &previousCharRange)
      guard let previousCharRangeValue else {
        return
      }

      var previousCharValue: AnyObject?
      let previousCharValueError = AXUIElementCopyParameterizedAttributeValue(
        element,
        kAXStringForRangeParameterizedAttribute as CFString,
        previousCharRangeValue,
        &previousCharValue
      )
      guard let previousCharValue = previousCharValue as? String, previousCharValueError == .success else {
        return
      }

      guard previousCharValue == "\n" else {
        return
      }

      var precedingTextRange = CFRangeMake(0, textRange.location - 1)

      let precedingTextRangeValue = AXValueCreate(.cfRange, &precedingTextRange)
      guard let precedingTextRangeValue else {
        return
      }

      var precedingTextValue: AnyObject?
      let precedingTextValueError = AXUIElementCopyParameterizedAttributeValue(
        element,
        kAXStringForRangeParameterizedAttribute as CFString,
        precedingTextRangeValue,
        &precedingTextValue
      )
      guard let precedingTextValue = precedingTextValue as? String, precedingTextValueError == .success else {
        return
      }

      let lines = precedingTextValue.components(separatedBy: .newlines).filter { !$0.isEmpty }

      let prefix = "/assist "
      guard let lastLine = lines.last, lastLine.hasPrefix(prefix) else {
        return
      }

      print(precedingTextValue)

      var cursorRange = CFRangeMake(0, 2)

      let cursorRangeValue = AXValueCreate(.cfRange, &cursorRange)
      guard let cursorRangeValue else {
        return
      }

      var boundsForRangeValue: AnyObject?
      let boundsForRangeValueError = AXUIElementCopyParameterizedAttributeValue(
        element,
        kAXBoundsForRangeParameterizedAttribute as CFString,
        precedingTextRangeValue,
        &boundsForRangeValue
      )
      guard let boundsForRangeValue, boundsForRangeValueError == .success else {
        return
      }

      var frame = CGRect()
      guard AXValueGetValue(boundsForRangeValue as! AXValue, .cgRect, &frame) else {
        return
      }

      var origin = carbonScreenPointFromCocoaScreenPoint(frame.origin)
      origin.y -= this.loadingWindow.contentView!.bounds.height
      origin.y -= frame.height

      this.loadingWindow.setFrameOrigin(origin)
      this.loadingWindow.isLoading = true

      this.loadingWindow.orderFront(nil)
      this.loadingWindow.makeKey()

      let command = precedingTextValue
      sendFakeRequest(command: command) { (result) in
        this.loadingWindow.isLoading = false
        this.loadingWindow.close()

        this.setValue("\(precedingTextValue)\n\(result)", element: element)
      }
   // Uncomment if you have OpenAI API key and want to use real request
   // sendOpenAIRequest(command: command) { (result) in
   //   DispatchQueue.main.async {
   //     this.loadingWindow.isLoading = false
   //     this.loadingWindow.close()
   //
   //     let resultValue = {
   //       if let result {
   //         let codeBlock = extractCodeBlock(from: result)
   //         if !codeBlock.isEmpty {
   //           return codeBlock
   //         } else {
   //           return result
   //         }
   //       } else {
   //         return "No result."
   //       }
   //     }()
   //
   //     this.setValue("\(precedingTextValue)\n\(resultValue)", element: element)
   //   }
   // }
    }

    let observerCreateError = AXObserverCreate(app.processIdentifier, observerCallback, &observer)
    guard let observer, observerCreateError == .success else {
      return
    }

    self.observers.append(observer)
    AXObserverAddNotification(
      observer,
      appElement,
      kAXSelectedTextChangedNotification as CFString,
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    )
    CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)
  }

  private func setValue(_ value: String, element: AXUIElement) {
    var isAttributeSettableValue = DarwinBoolean(false)

    let isAttributeSettableValueError = AXUIElementIsAttributeSettable(
      element,
      kAXValueAttribute as CFString,
      &isAttributeSettableValue
    )

    guard isAttributeSettableValueError == .success else {
      return
    }

    if isAttributeSettableValue.boolValue {
      AXUIElementSetAttributeValue(
        element,
        kAXValueAttribute as CFString,
        value as CFString
      )
      return
    }
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
