import AppKit
import ScreenCaptureKit

func carbonScreenPointFromCocoaScreenPoint(_ cocoaPoint: CGPoint) -> CGPoint {
  var foundScreen: NSScreen?
  var thePoint = CGPoint.zero

  for screen in NSScreen.screens {
    if NSPointInRect(cocoaPoint, screen.frame) {
      foundScreen = screen
    }
  }

  if let foundScreen = foundScreen {
    let screenHeight = foundScreen.frame.size.height
    thePoint = CGPoint(x: cocoaPoint.x, y: screenHeight - cocoaPoint.y - 1)
  }

  return thePoint
}

func cocoaScreenPointFromCarbonScreenPoint(_ carbonPoint: CGPoint) -> CGPoint {
  CGPoint(x: carbonPoint.x, y: NSScreen.screens[0].frame.size.height - carbonPoint.y)
}

// ScreenCaptureKit version
func captureScreen(rect: CGRect) async throws -> CGImage? {
  let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
  guard let mainDisplayID = NSScreen.main?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
        let display = content.displays.first(where: { $0.displayID == mainDisplayID }) else { return nil }

  let streamConfig = SCStreamConfiguration()
  streamConfig.captureResolution = .automatic
  streamConfig.sourceRect = rect
  streamConfig.preservesAspectRatio = true
  streamConfig.scalesToFit = true
  streamConfig.capturesAudio = false
  streamConfig.excludesCurrentProcessAudio = true

  let filter = SCContentFilter(display: display, excludingWindows: [])

  let capturedImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: streamConfig)
  return capturedImage
}

// CGWindowListCreateImage version
func captureScreen(rect: CGRect) -> CGImage? {
  let screenShot = CGWindowListCreateImage(
    rect,
    [.optionOnScreenOnly, .excludeDesktopElements],
    kCGNullWindowID,
    [.boundsIgnoreFraming, .bestResolution]
  )

  return screenShot
}
