//
//  String+Extension.swift
//  SimpleHTMLParser
//
//

import Foundation
import UIKit

extension String {
    func subString(range: NSRange) -> String {
        let subString = self[(self.index(self.startIndex, offsetBy: range.location))..<(self.index(self.startIndex, offsetBy: range.location + range.length))]
        return String(subString)
    }
    func subString(start: Int, length: Int) -> String {
        let subString = self[(self.index(self.startIndex, offsetBy: start))..<(self.index(self.startIndex, offsetBy: start + length))]
        return String(subString)
    }
}
extension String {
    func cgFloat() -> CGFloat {
        guard let num = NumberFormatter().number(from: self) else { return 0 }
        return CGFloat(truncating: num)
    }
}
