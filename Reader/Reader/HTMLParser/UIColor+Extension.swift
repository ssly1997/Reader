//
//  UIColor+Extension.swift
//  SimpleHTMLParser
//
//

import Foundation
import UIKit



extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat((hexNumber & 0x0000ff) ) / 255
                    a = 1.0
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        self.init(red: 0x00, green: 0x00, blue: 0x00, alpha: 1.0)
    }
    convenience init?(cssRgbValue: String) {
        guard cssRgbValue.count > 0 && cssRgbValue.hasPrefix("rgb") && cssRgbValue.hasSuffix(")") else { return nil }
        let rgbValue = cssRgbValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if rgbValue.starts(with: "rgba(") {
            let rgba = String.init(rgbValue[rgbValue.index(rgbValue.startIndex, offsetBy: 5)..<(rgbValue.index(rgbValue.endIndex, offsetBy: -1))])
            let tmps = rgba.split(separator: ",").map { String($0) }
            if tmps.count == 4 {
                let r = tmps[0].cgFloat()
                let g = tmps[1].cgFloat()
                let b = tmps[2].cgFloat()
                let a = tmps[3].cgFloat()
                self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a / 255.0)
                return
            }
        } else if rgbValue.starts(with: "rgb(") {
            let rgba = String.init(rgbValue[rgbValue.index(rgbValue.startIndex, offsetBy: 4)..<(rgbValue.index(rgbValue.endIndex, offsetBy: -1))])
            let tmps = rgba.split(separator: ",").map { String($0) }
            if tmps.count == 4 {
                let r = tmps[0].cgFloat()
                let g = tmps[1].cgFloat()
                let b = tmps[2].cgFloat()
                let a: CGFloat = 255
                self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a / 255.0)
                return
            }
        }
        self.init(red: 0x00, green: 0x00, blue: 0x00, alpha: 1.0)
    }
}
