//
//  SimpleHTMLParser+Utility.swift
//  SimpleHTMLParser
//
//

import Foundation

func compileRegularExpression(_ pattern: String) -> NSRegularExpression? {
    guard let regularExpression = try? NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
    return regularExpression
}
