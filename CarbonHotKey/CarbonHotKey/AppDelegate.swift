import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    var hotKeyRef: EventHotKeyRef?
    let modifierFlags: UInt32 = getCarbonFlagsFromCocoaFlags(cocoaFlags: [.command, .shift])

    let keyCode = kVK_ANSI_Y
    var gMyHotKeyID = EventHotKeyID()

    gMyHotKeyID.id = 0

    var eventType = EventTypeSpec()
    eventType.eventClass = OSType(kEventClassKeyboard)
    eventType.eventKind = OSType(kEventHotKeyReleased)

    InstallEventHandler(
      GetApplicationEventTarget(),
      { (nextHanlder, theEvent, userData) -> OSStatus in
        NSLog("Press ⌘ + Shift + Y pressed!")
        return noErr
      },
      1,
      &eventType,
      nil,
      nil
    )

    let status = RegisterEventHotKey(
      UInt32(keyCode),
      modifierFlags,
      gMyHotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    print(status == noErr)
  }
}

func getCarbonFlagsFromCocoaFlags(cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
  let flags = cocoaFlags.rawValue
  var newFlags: Int = 0

  if ((flags & NSEvent.ModifierFlags.control.rawValue) > 0) {
    newFlags |= controlKey
  }

  if ((flags & NSEvent.ModifierFlags.command.rawValue) > 0) {
    newFlags |= cmdKey
  }

  if ((flags & NSEvent.ModifierFlags.shift.rawValue) > 0) {
    newFlags |= shiftKey;
  }

  if ((flags & NSEvent.ModifierFlags.option.rawValue) > 0) {
    newFlags |= optionKey
  }

  if ((flags & NSEvent.ModifierFlags.capsLock.rawValue) > 0) {
    newFlags |= alphaLock
  }

  return UInt32(newFlags);
}
