//
//  SimpleHTMLElementTagType.swift
//  SimpleHTMLParser
//
//

import Foundation

enum SimpleHTMLElementTagType : Int {
    case unknow = 0
    case root = 1
    case text
    case p
    case div
    case br
    case em
    case strong
    case a
    case span
    case font
    case img
}
extension SimpleHTMLElementTagType {
    /// 是否可以包含子标签
    func canLayEggs() -> Bool {
        return self != .img && self != .br
    }
    /// 需要被渲染的标签,其它标签都是功能标签
    func requireRender() -> Bool {
        return self == .text || self == .img || self == .br
    }
}

let simpleHTMLElementTagTypeMapping: [String: SimpleHTMLElementTagType] = [
    "p": .p,
    "div": .div,
    "br": .br,
    "em": .em,
    "strong": .strong,
    "a": .a,
    "span": .span,
    "font": .font,
    "img": .img
    
]

func getSimpleHTMLElementTagType(by typeText: String) -> SimpleHTMLElementTagType {
    guard let type = simpleHTMLElementTagTypeMapping[typeText] else { return .unknow}
    return type
}
