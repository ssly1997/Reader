//
//  SimpleHTMLParser.swift
//  SimpleHTMLParser
//

//

import Foundation
import UIKit

public class SimpleHTMLParser {
    private var context: SimpleHTMLParserContext!
    public func parse(html: String, defaultFontSize: CGFloat = 15, defaultFontColor: UIColor = .black) -> SimpleHTMLElement? {
        guard html.count > 0 else { return nil }
        self.context = .init()
        self.context.rawHTML = html
        self.context.cur = 0
        let rootElement = SimpleHTMLElement.init()
        rootElement.type = .root
        rootElement.rawHTML = html
        rootElement.defaultTextColor = defaultFontColor
        rootElement.defaultFontSize = defaultFontSize
        self.context.pushElement(rootElement)
        rootElement.children = self.parseChildren()
        return rootElement
    }
    
    private func parseChildren() -> [SimpleHTMLElement] {
        var children = [SimpleHTMLElement]()
        while !self.context.isEnd {
            guard let source = self.context.readCurrentSource(), source.count > 0 else { break }
            var element: SimpleHTMLElement? = nil
            /// 标签的开头
            if source.hasPrefix("<") {
                if source.hasPrefix("</") {
                    /// 结束标签
                    let startCur = self.context.cur
                    element = self.parseElement(.tail)
                    let endCur = self.context.cur
                    if let element = element {
                        let subString = self.context.rawHTML.subString(start: startCur, length: endCur - startCur)
                        element.rawHTML = String(subString)
                    }
                    /// 解析完当前标签,将当前标签从栈顶弹出
                    self.context.popElement()
                    break
                } else {
                    /// 开始标签
                    let startCur = self.context.cur
                    element = self.parseElement(.head)
                    if let element = element {
                        if !element.isSelfClosingTag && element.type.canLayEggs() {
                            self.context.pushElement(element)
                            element.children = self.parseChildren()
                        }
                    }
                    let endCur = self.context.cur
                    let subString = self.context.rawHTML.subString(start: startCur, length: endCur - startCur)
                    element?.rawHTML = String(subString)
                }
            } else {
                /// 不是标签的开头,则解析成纯文本数据
                element = self.parseTextElement()
            }
            if let element = element {
                children.append(element)
            }
        }
        return children
    }
    private func parseElement(_ location: SimpleHTMLElementLocation) -> SimpleHTMLElement? {
        var element: SimpleHTMLElement? = nil
        guard let parent = self.context.topElement(), let source = self.context.readCurrentSource() else { return nil }
        /// 匹配'<'(开始标签)或'</'(结束标签)开头的字符串,中间不能有空格,也不能出现'/','>','<','='
        guard let regularExp = compileRegularExpression("^<\\/?([a-z][^\t\r\n /><=]*)") else { fatalError() }
        guard let result = regularExp.firstMatch(in: source, options: .init(rawValue: 0), range: .init(location: 0, length: source.count)) else { return nil }
        let tagContent = source.subString(range: result.range)
        self.context.advance(by: result.range)
        let tagName = readTagName(from: tagContent, location: location)
        if location == .head {
            /// 开始解析标签属性
            element = .init()
            element?.parent = parent
            let attributes = self.parseAttributes()
            self.context.trimLeftSpace()
            var isSelfClosing = false
            var validTag = false
            /// 属性解析完成,判断开始标签是否解析正常
            if let source = self.context.readCurrentSource() {
                if source.hasPrefix(">") {
                    isSelfClosing = false
                    validTag = true
                    self.context.advancd(by: 1)
                } else if source.hasPrefix("/>") {
                    isSelfClosing = true
                    validTag = true
                    self.context.advancd(by: 2)
                }
            }
            if validTag {
                element?.attributes = attributes
                element?.isSelfClosingTag = isSelfClosing
                element?.tagName = tagName
                element?.type = getSimpleHTMLElementTagType(by: tagName)
            }
        } else {
            /// 开始解析结束标签
            self.context.trimLeftSpace()
            if let source = self.context.readCurrentSource() {
                if tagName == parent.tagName && source.hasPrefix(">") {
                    /// 结束标签的名称与当前正在解析的标签名称一致,正常结束
                    parent.isSelfClosingTag = false
                    self.context.advancd(by: 1)
                } else {
                    /// 异常的标签,将数据作为纯文本展示
                    element = .buildTextElement(tagContent, parent: parent)
                }
            }
        }
        return element
    }
    private func parseTextElement() -> SimpleHTMLElement? {
        guard let parent = self.context.topElement(), let source = self.context.readCurrentSource() else { return nil }
        /// 匹配所有的字符,除了'<', '>'
        guard let regularExp = compileRegularExpression("^[\\s\\S]([^<>])*"),
              let result = regularExp.firstMatch(in: source, options: .init(rawValue: 0), range: .init(location: 0, length: source.count)) else { fatalError() }
        var text = source.subString(range: result.range)
        self.context.advance(by: result.range)
        /// 路过异常的标签数据
        while let source = self.context.readCurrentSource(),
              source.hasPrefix("<<") || source.hasPrefix(">>") || source.hasPrefix("<>") || source.hasPrefix("><") {
            text.append(source.subString(start: 0, length: 1))
            self.context.advancd(by: 1)
        }
        return .buildTextElement(text, parent: parent)
    }
    
    private func parseAttributes() -> [SimpleHTMLElementAttribute] {
        var attributes = [SimpleHTMLElementAttribute]()
        guard let attributeNameRegularExp = compileRegularExpression("[^\t\r\n />][^\t\r\n />=]*"),
              let attributeEqualRegularExp = compileRegularExpression("^[\t\r\n ]*="),
              let attributeQuoteRegularExp = compileRegularExpression("^[\t\r\n ]*['\"][^\t\r\n<>=]*['\"]") else { fatalError() }
        while let source = self.context.readCurrentSource() ,
              !self.context.isEnd && !source.hasPrefix(">") && !source.hasPrefix("/>") {
            /// 解析属性名称
            guard let attributeNameMatchResult = attributeNameRegularExp.firstMatch(in: source,
                                                                                    options: .init(rawValue: 0),
                                                                                    range: .init(location: 0, length: source.count)) else { break }
            let attributeNameText = source.subString(range: attributeNameMatchResult.range)
            self.context.advance(by: attributeNameMatchResult.range)
            /// 解析属性后面的'='
            guard let source = self.context.readCurrentSource(),
                  let attributeEqualMathResult = attributeEqualRegularExp.firstMatch(in: source,
                                                                                     options: .init(rawValue: 0),
                                                                                     range: .init(location: 0, length: source.count)) else { break }
            self.context.advance(by: attributeEqualMathResult.range)
            
            guard let source = self.context.readCurrentSource(),
                  let attributeQuoteMathResult = attributeQuoteRegularExp.firstMatch(in: source,
                                                                                     options: .init(rawValue: 0),
                                                                                     range: .init(location: 0, length: source.count)) else { break }
            var attributeQuoteText: String = source.subString(range: attributeQuoteMathResult.range)
            /// 去掉引号前多余的空格
            while attributeQuoteText.hasPrefix(" ") {
                attributeQuoteText = attributeQuoteText.subString(start: 1, length: attributeQuoteText.count - 1)
            }
            /// 去掉两边的引号
            attributeQuoteText = attributeQuoteText.subString(start: 1, length: attributeQuoteText.count - 2)
            if attributeNameText == "style" {
                let styleValues = attributeQuoteText.split(separator: ";")
                let ats: [SimpleHTMLElementAttribute] = styleValues.map {
                    let tmps = $0.split(separator: ":")
                    if tmps.count == 2 {
                        let key = tmps[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = tmps[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let attribute = SimpleHTMLElementAttribute.init(key: key, value: value)
                        return attribute
                    }
                    return nil
                }.filter { $0 != nil }.map { $0! }
                attributes.append(contentsOf: ats)
            } else {
                let attribute = SimpleHTMLElementAttribute.init(key: attributeNameText, value: attributeQuoteText)
                attributes.append(attribute)
            }
            self.context.advance(by: attributeQuoteMathResult.range)
            self.context.trimLeftSpace()
        }
        return attributes
    }
}
