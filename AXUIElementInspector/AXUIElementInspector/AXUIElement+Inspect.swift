import Cocoa

func inspect(element: AXUIElement, level: Int = 0) -> NSAttributedString {
  let description = NSMutableAttributedString()

  var roleValue: AnyObject?
  let roleValueError = AXUIElementCopyAttributeValue(
    element,
    kAXRoleAttribute as CFString,
    &roleValue
  )
  if let roleValue, roleValueError == .success {
    description.append(
      NSAttributedString(
        string: "\(String(repeating: " ", count: level * 2))\(roleValue)\n",
        attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)]
      )
    )
  }

  var attributeNames = CFArrayCreate(nil, nil, 0, nil)
  AXUIElementCopyAttributeNames(element, &attributeNames)

  if let attributeNames = attributeNames as? [String] {
    for attributeName in attributeNames {
      var attributeValue: AnyObject?

      let attributeValueError = AXUIElementCopyAttributeValue(
        element,
        attributeName as CFString,
        &attributeValue
      )
      if attributeValueError == .success {
        description.append(
          NSAttributedString(
            string: "\(String(repeating: " ", count: (level + 1) * 2))\(attributeName): ",
            attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)]
          )
        )

        let value = attributeValue as! AXValue
        if AXValueGetType(value) == .cgPoint {
          var p = CGPoint()
          AXValueGetValue(value, .cgPoint, &p)
          description.append(
            NSAttributedString(
              string: "\(NSStringFromPoint(p))\n",
              attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
            )
          )
        } else if AXValueGetType(value) == .cgSize {
          var s = CGSize()
          AXValueGetValue(value, .cgSize, &s)
          description.append(
            NSAttributedString(
              string: "\(NSStringFromSize(s))\n",
              attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
            )
          )
        } else if AXValueGetType(value) == .cgRect {
          var r = CGRect()
          AXValueGetValue(value, .cgRect, &r)
          description.append(
            NSAttributedString(
              string: "\(NSStringFromRect(r))\n",
              attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
            )
          )
        } else if AXValueGetType(value) == .cfRange {
          var r = CFRange()
          AXValueGetValue(value, .cfRange, &r)
          description.append(
            NSAttributedString(
              string: "\(NSStringFromRange(NSRange(location: r.location, length: r.length)))\n",
              attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
            )
          )
        } else {
          if attributeName == "AXValue" {
            description.append(
              NSAttributedString(
                string: "...\n",
                attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
              )
            )
          } else {
            if attributeName == kAXParentAttribute {
              var parentValue: AnyObject?
              let parentValueError = AXUIElementCopyAttributeValue(
                element,
                kAXParentAttribute as CFString,
                &parentValue
              )
              if let parentValue, parentValueError == .success {
                var roleValue: AnyObject?
                let roleValueError = AXUIElementCopyAttributeValue(
                  parentValue as! AXUIElement,
                  kAXRoleAttribute as CFString,
                  &roleValue
                )
                if let roleValue, roleValueError == .success {
                  description.append(
                    NSAttributedString(
                      string: "\(roleValue)\n",
                      attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
                    )
                  )
                }
              }
            } else if attributeName == kAXTopLevelUIElementAttribute {
              var topLevelUIElementValue: AnyObject?
              let topLevelUIElementValueError = AXUIElementCopyAttributeValue(
                element,
                kAXTopLevelUIElementAttribute as CFString,
                &topLevelUIElementValue
              )
              if let topLevelUIElementValue, topLevelUIElementValueError == .success {
                var roleValue: AnyObject?
                let roleValueError = AXUIElementCopyAttributeValue(
                  topLevelUIElementValue as! AXUIElement,
                  kAXRoleAttribute as CFString,
                  &roleValue
                )
                if let roleValue, roleValueError == .success {
                  description.append(
                    NSAttributedString(
                      string: "\(roleValue)\n",
                      attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
                    )
                  )
                }
              }
            } else {
              if let children = attributeValue as? [AXUIElement] {
                let roles = children.compactMap { (child) in
                  var roleValue: AnyObject?
                  let roleValueError = AXUIElementCopyAttributeValue(
                    child,
                    kAXRoleAttribute as CFString,
                    &roleValue
                  )
                  if let roleValue, roleValueError == .success {
                    return roleValue
                  } else {
                    return nil
                  }
                }
                description.append(
                  NSAttributedString(
                    string: "\(roles)\n",
                    attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
                  )
                )
                if level < 1 {
                  for child in children {
                    let subDescription = inspect(element: child, level: level + 2)
                    description.append(subDescription)
                  }
                }
              } else {
                description.append(
                  NSAttributedString(
                    string: "\(value)\n",
                    attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)]
                  )
                )
              }
            }
          }
        }
      }
    }
  }

  return description
}

func title(of element: AXUIElement) -> String {
  var components = [String]()

  var titleValue: AnyObject?
  let titleValueError = AXUIElementCopyAttributeValue(
    element,
    kAXTitleAttribute as CFString,
    &titleValue
  )
  if let titleValue, titleValueError == .success {
    let title = "\(titleValue)"
    if !title.isEmpty {
      components.append(title)
    }
  }

  var descriptionValue: AnyObject?
  let descriptionValueError = AXUIElementCopyAttributeValue(
    element,
    kAXDescription as CFString,
    &descriptionValue
  )
  if let descriptionValue, descriptionValueError == .success {
    let description = "\(descriptionValue)"
    if !description.isEmpty {
      components.append(description)
    }
  }

  var roleDescriptionValue: AnyObject?
  let roleDescriptionValueError = AXUIElementCopyAttributeValue(
    element,
    kAXRoleDescriptionAttribute as CFString,
    &roleDescriptionValue
  )
  if let roleDescriptionValue, roleDescriptionValueError == .success {
    let roleDescription = "\(roleDescriptionValue)"
    if !roleDescription.isEmpty {
      components.append(roleDescription)
    }
  }

  return components.joined(separator: ", ")
}
