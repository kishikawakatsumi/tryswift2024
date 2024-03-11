import AppKit

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
