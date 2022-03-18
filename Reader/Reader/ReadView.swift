//
//  ReaderView.swift
//  Reader
//
//  Created by 李方长 on 2021/12/15.
//

import Foundation
import UIKit

class ReadView : UIView {
    
    var content:String = "hello~"
    var ctFrame:CTFrame? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.init(hexString: "#e5e5e5")
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let frame = ctFrame else {
            return
        }
        let context = UIGraphicsGetCurrentContext()!
        context.textMatrix = .identity
        context.translateBy(x: 0, y: self.bounds.size.height + kNavigationBarTop)
        context.scaleBy(x: 1.0, y: -1.0)
        CTFrameDraw(frame, context)
    }
    
}
