//
//  CellView.swift
//  Reader
//
//  Created by 李方长 on 2021/12/25.
//

import Foundation
import UIKit

protocol SDZCatalogTableViewCellDelegate:AnyObject {
    func catalog(catalogCell:SDZCatalogTableViewCell, didSelectChapter chapter:Int)
}

class SDZCatalogTableViewCell:UITableViewCell {
    weak open var delegate:SDZCatalogTableViewCellDelegate? = nil
    var title:String = ""
    var index:Int = 0
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = UIColor.white
        self.contentView.backgroundColor = UIColor.white
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(button)
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.left.equalTo(self.contentView).offset(20)
        }
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func config(title:String, index:Int, sepcial:Bool) {
        titleLabel.text = title
        self.index = index
        if sepcial {
            self.titleLabel.textColor = UIColor.init(hexString: "#44bdf4")
        } else {
            self.titleLabel.textColor = UIColor.black
        }
    }
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.text = self.title
        return label
    }()
    
    var button:UIButton {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(self.clickAction), for: .touchUpInside)
        btn.frame = self.frame
        return btn
    }
    
    @objc func clickAction() {
        delegate?.catalog(catalogCell: self, didSelectChapter: index)
    }
}

protocol SDZBookShelfCollectionViewCellDelegate:AnyObject {
    func bookShelfCell(_ cell:SDZBookShelfCollectionViewCell, didClick title:String)
}

class SDZBookShelfCollectionViewCell:UICollectionViewCell {
    
    weak open var delegate:SDZBookShelfCollectionViewCellDelegate? = nil
    var title:String = ""
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.text = "这是一本书"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.white
        label.textAlignment = .center
        return label
    }()
    
    func configCell(title:String) {
        var title = title
        self.title = title
        title = title.replacingOccurrences(of: ".txt", with: "")
        if title.count > 5 {
            title = title.prefix(5)+"..."
        }
        titleLabel.text = title
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.red
        setupSubViews()
        addGeture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self).offset(-10)
        }
    }
    
    private func addGeture() {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(self.clickAction))
        self.addGestureRecognizer(tap)
    }
    
    @objc func clickAction() {
        delegate?.bookShelfCell(self, didClick: title)
        printTime()
    }
    
}
