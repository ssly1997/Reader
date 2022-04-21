//
//  SimpleHTMLElementRender.swift
//  SimpleHTMLParser
//
//

import Foundation
import UIKit

typealias SimpleHTMLElementRender = (_ element: SimpleHTMLElement) -> NSAttributedString

let rawTextRender: SimpleHTMLElementRender = {
    if $0.value.count > 0 {
        return .init(string: $0.value)
    } else {
        return .init(string: $0.rawHTML)
    }
}
let emptyRender: SimpleHTMLElementRender = {
    _ in
    return NSMutableAttributedString.init()
}
let textRender: SimpleHTMLElementRender = {
    
    let range: NSRange = .init(location: 0, length: $0.value.count)
    let attributedString = NSMutableAttributedString.init(string: $0.value)
    
    let fontSize = $0.getFontSize()
    var font = UIFont.systemFont(ofSize: fontSize)
    var traits = font.fontDescriptor.symbolicTraits
    if $0.getIsItalic() { traits.insert(.traitItalic) }
    if $0.getIsBold() { traits.insert(.traitBold) }
    if let nFontDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
        font = UIFont.init(descriptor: nFontDescriptor, size: fontSize)
    }
    attributedString.addAttribute(.font, value: font, range: range)
    if let textColor = $0.getTextColor() {
        attributedString.addAttribute(.foregroundColor, value: textColor, range: range)
    }
    if traits.contains(.traitItalic) {
        attributedString.addAttribute(.obliqueness, value: 0.2, range: range)
    }
    if let linkUrl = $0.getLinkUrl() {
        attributedString.addAttribute(.link, value: linkUrl, range: range)
    }
    if $0.containsInParagraph() {
        let paragraphStyle = NSMutableParagraphStyle.init()
        paragraphStyle.alignment = .natural
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 12
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        attributedString.append(NSAttributedString.init(string: "\n"))
    }
    return attributedString
}

let brRender: SimpleHTMLElementRender = { _ in
    return NSAttributedString.init(string: "\n")
}
let imgRender: SimpleHTMLElementRender = {
    guard let imgUrl = $0.getImgUrl(),
          let url = URL.init(string: imgUrl),
          let data = try? Data.init(contentsOf: url),
          let image = UIImage.init(data: data) else { return .init(string: "[img]")}
    let attachment = NSTextAttachment.init()
    attachment.image = image
    let imgAttributedString = NSAttributedString.init(attachment: attachment)
    return imgAttributedString
}


let renderMapping: [SimpleHTMLElementTagType: SimpleHTMLElementRender] = [
    .text: textRender,
    .br: brRender,
    .img: imgRender
]
