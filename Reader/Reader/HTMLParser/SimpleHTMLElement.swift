//
//  SimpleHTMLElement.swift
//  SimpleHTMLParser
//
//

import Foundation
import UIKit

enum SimpleHTMLElementLocation {
    case head
    case tail
}
struct SimpleHTMLElementAttribute {
    var key: String
    var value: String
}

public class SimpleHTMLElement {
    var type: SimpleHTMLElementTagType = .unknow
    var isSelfClosingTag = false
    var children: [SimpleHTMLElement] = .init()
    var attributes: [SimpleHTMLElementAttribute] = .init()
    var value = ""
    var tagName = ""
    var parent: SimpleHTMLElement? = nil
    var rawHTML = ""
    var defaultFontSize: CGFloat = 15
    var defaultTextColor: UIColor = .black
    
    func render() -> NSAttributedString? {
        let attributedString = NSMutableAttributedString.init()
        if self.children.count > 0 {
            self.children.forEach {
                if let subAttributedString = $0.render() {
                    attributedString.append(subAttributedString)
                }
            }
        } else {
            if let render = renderMapping[self.type] {
                attributedString.append(render(self))
            }
        }
        return attributedString
    }
}


extension SimpleHTMLElement {
    static func buildTextElement(_ text: String, parent: SimpleHTMLElement) -> SimpleHTMLElement {
        let element = SimpleHTMLElement.init()
        element.type = .text
        element.value = text
        element.parent = parent
        element.children = []
        element.isSelfClosingTag = true
        element.rawHTML = text
        return element
    }
}
extension SimpleHTMLElement {
    func getAttributeValue(by key: String) -> String? {
        guard let attribute = (self.attributes.first { $0.key == key }) else { return nil }
        return attribute.value
    }
    func getFontSize() -> CGFloat {
        guard let fontSizeValue = (self.attributes.first { $0.key == "font-size" })?.value else { return self.getParentFontSize() }
        return fontSizeValue.cgFloat()
       
    }
    func getTextColor() -> UIColor? {
        guard let textColor = (self.attributes.first { $0.key == "color" })?.value else { return self.getParentFontColor() }
        return UIColor.init(hex: textColor)
    }
    func getParentFontSize() -> CGFloat {
        var parent: SimpleHTMLElement? = self.parent
        var fontSize: CGFloat = 0
        while parent != nil {
            let parentFontSize = parent!.getFontSize()
            if parentFontSize > 0 {
                fontSize = parentFontSize
                break
            }
            parent = parent!.parent
        }
        return fontSize == 0 ? defaultFontSize : fontSize
    }
    func getParentFontColor() -> UIColor? {
        var parent: SimpleHTMLElement? = self.parent
        var fontColor: UIColor? = nil
        while parent != nil {
            let parentTextColor = parent?.getTextColor()
            if let parentTextColor = parentTextColor {
                fontColor = parentTextColor
                break
            }
            parent = parent!.parent
        }
        return fontColor ?? defaultTextColor
    }
    func getIsItalic() -> Bool {
        var parent: SimpleHTMLElement? = self.parent
        while parent != nil {
            if parent!.type == .em  {
                return true
            }
            parent = parent!.parent
        }
        return false
    }
    func getIsBold() -> Bool {
        var parent: SimpleHTMLElement? = self.parent
        while parent != nil {
            if parent!.type == .strong  {
                return true
            }
            parent = parent!.parent
        }
        return false
    }
    
    func getLinkUrl() -> String? {
        var parent: SimpleHTMLElement? = self.parent
        while parent != nil {
            if parent!.type == .a, let linkUrl = parent?.getAttributeValue(by: "href")  {
                return linkUrl
            }
            parent = parent!.parent
        }
        return nil
    }
    func containsInParagraph() -> Bool {
        var parent: SimpleHTMLElement? = self.parent
        while parent != nil {
            if parent!.type == .p  {
                return true
            }
            parent = parent!.parent
        }
        return false
    }
    func getImgUrl() -> String? {
        guard let imgUrl = self.getAttributeValue(by: "src") else { return nil }
        return imgUrl
    }
}
