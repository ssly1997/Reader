//
//  ReaderViewController.swift
//  Reader
//
//  Created by 李方长 on 2021/12/23.
//

import Foundation
import UIKit

class ReadViewController:UIViewController {
    private var _content:String?
    private var _chapterTitle:String?
    private var _progress:String?
    private var _time:String?
    private var _attContent:NSAttributedString?
    var attContent:NSAttributedString? {
        set {
            _attContent = newValue
            if _attContent == nil || _attContent?.length == 0 {
                return
            }
            readView.removeFromSuperview()
            chapterTitleLabel.removeFromSuperview()
            readView = ReadView()
            setupSubviews()
        }
        get {
            return _attContent
        }
    }
    var content:String? {
        set {
            _content = newValue
            if _content == nil || _content?.count == 0 {
                return
            }
            readView.removeFromSuperview()
            chapterTitleLabel.removeFromSuperview()
            readView = ReadView()
            setupSubviews()
        }
        get {
            return _content
        }
    }
    var progress:String? {
        set {
            _progress = newValue
            progressLabel.text = newValue
        }
        get {
            return _progress
        }
    }
    var time:String? {
        set {
            _time = newValue
            timeLabel.text = newValue
        }
        get {
            return _time
        }
    }
    var chapterTitle:String? {
        set {
            _chapterTitle = newValue
            guard var title = newValue else {
                return
            }
            if title.count > 15 {
                title = title.prefix(15)+"..."
            }
            chapterTitleLabel.text = title
        }
        get {
            return _chapterTitle
        }
    }
    private lazy var readView:ReadView = {
        return ReadView()
    }()
    private lazy var chapterTitleLabel:UILabel = {
        let label = UILabel()
        label.text = "章节标题"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.textColor = UIColor.init(hexString: "#615c5c")
        label.alpha = 0.7
        return label
    }()
    private lazy var progressLabel:UILabel = {
        let label = UILabel()
        label.text = "12.1%"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.init(hexString: "#615c5c")
        label.alpha = 0.7
        return label
    }()
    private lazy var timeLabel:UILabel = {
        let label = UILabel()
        label.text = "12:11"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.init(hexString: "#615c5c")
        label.alpha = 0.7
        return label
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    private func setupSubviews() {
        readView.frame = self.view.frame
        if content != nil {
            readView.ctFrame = SDZReadParser.parserTxt(content: content ?? "默认文案", config: SDZReadConfig.shared, bounds: kReadRect)
        } else if attContent != nil {
            readView.ctFrame = SDZReadParser.parserEpub(content: attContent ?? NSAttributedString(), bounds: kReadRect)
        } else {
            assert(false, "error")
        }
        self.view.addSubview(readView)
        self.view.addSubview(self.chapterTitleLabel)
        self.view.addSubview(self.progressLabel)
        self.view.addSubview(self.timeLabel)
        chapterTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.view).offset(20)
            make.top.equalTo(self.view).offset(50)
        }
        progressLabel.snp.makeConstraints { make in
            make.right.equalTo(self.view).offset(-30)
            make.bottom.equalTo(self.view).offset(-40)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.view).offset(30)
            make.centerY.equalTo(progressLabel)
        }
    }
}

