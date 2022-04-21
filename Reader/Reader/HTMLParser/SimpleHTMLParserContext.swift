//
//  SimpleHTMLParserContext.swift
//  SimpleHTMLParser
//
//

import Foundation

class SimpleHTMLParserContext {
    /// 是否支持自闭合标签<br/>、<img>等,默认支持
    var isSupportSelfClosingTag = true
    var rawHTML = ""
    var cur = 0
    var parseStack: [SimpleHTMLElement] = .init()
    
}
extension SimpleHTMLParserContext {
    func pushElement(_ element: SimpleHTMLElement) {
        self.parseStack.append(element)
    }
    @discardableResult
    func popElement() -> SimpleHTMLElement? {
        return self.parseStack.popLast()
    }
    func topElement() -> SimpleHTMLElement? {
        return self.parseStack.last
    }
}

extension SimpleHTMLParserContext {
    var isEnd: Bool {
        guard rawHTML.count > 0 else { return true }
        return self.cur >= self.rawHTML.count - 1
    }
    func readCurrentSource() -> String? {
        guard !isEnd else { return nil }
        let subString = self.rawHTML[(self.rawHTML.index(self.rawHTML.startIndex, offsetBy: self.cur))..<(self.rawHTML.endIndex)]
        return String.init(subString)
    }
    func advance(by range: NSRange) {
        self.cur += range.location
        self.cur += range.length
    }
    func advancd(by length: Int) {
        self.cur += length
    }
    func trimLeftSpace() {
        while let source = self.readCurrentSource(),
              source.starts(with: " ") {
            self.advancd(by: 1)
        }
    }
}
