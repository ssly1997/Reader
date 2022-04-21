//
//  SimpleHTMLElement+Extension.swift
//  SimpleHTMLParser
//
//

import Foundation

func readTagName(from source: String, location: SimpleHTMLElementLocation) -> String {
    guard source.count > 0 else { return "" }
    if location == .head {
        guard source.count >= 2 else { return "" }
        let tagName = source[source.index(source.startIndex, offsetBy: 1)..<(source.index(source.endIndex, offsetBy: 0))]
        return String(tagName)
    } else {
        guard source.count >= 3 else { return "" }
        let tagName = source[source.index(source.startIndex, offsetBy: 2)..<(source.index(source.endIndex, offsetBy: 0))]
        return String(tagName)
    }
}
