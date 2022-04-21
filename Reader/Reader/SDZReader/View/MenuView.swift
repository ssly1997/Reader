//
//  Menu.swift
//  Reader
//
//  Created by 李方长 on 2021/12/25.
//

import Foundation
import UIKit

protocol MenuViewDelegate:AnyObject {
    func menuView(didClickBack view:MenuView)
    func menuView(didClickCatalog view:MenuView)
    func menuView(didClickProgress view:MenuView)
    func menuView(_ view:MenuView, didChangeFont font:UIFont)
}

class MenuView:UIView, UIGestureRecognizerDelegate, SettingsViewDelegate {
    weak open var delegate:MenuViewDelegate? = nil
    
    lazy var titleLabel:UILabel = {
        let label = UILabel()
        label.text = "小说名字"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.textColor = UIColor.black
        return label
    }()
    
    lazy var topMenuView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var bottomMenuView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    lazy var backButton:UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage.init(named: "back_black"), for: .normal)
        btn.addTarget(self, action: #selector(self.backClickAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var moreButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("•••", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.alpha = 0.7
        return btn
    }()
    
    lazy var catalogButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("📖", for: .normal)
        btn.titleLabel!.font = UIFont.systemFont(ofSize: 20)
        btn.addTarget(self, action: #selector(self.catalogClickAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var progressButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("⚽️", for: .normal)
        btn.titleLabel!.font = UIFont.systemFont(ofSize: 20)
        btn.addTarget(self, action: #selector(self.progressClckAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var progressLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "进度"
        label.textColor = UIColor.black
        label.textAlignment = .center
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(self.progressClckAction))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    lazy var catalogLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "目录"
        label.textColor = UIColor.black
        label.textAlignment = .center
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(self.catalogClickAction))
        label.addGestureRecognizer(tap)
        return label
    }()
    
    lazy var settingsButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("⚙️", for: .normal)
        btn.titleLabel!.font = UIFont.systemFont(ofSize: 20)
        btn.addTarget(self, action: #selector(self.settingsClickAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var settingsLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "设置"
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
        addGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAnimation() {
        layoutIfNeeded()
        let animationTop = CABasicAnimation.init(keyPath: "position.y")
        animationTop.toValue = topMenuView.frame.origin.y + topMenuView.frame.size.height/2
        animationTop.fromValue = topMenuView.frame.origin.y - topMenuView.frame.size.height/2
        animationTop.duration = 0.3
        topMenuView.layer.add(animationTop, forKey: "showTop")
        
        let animationBottom = CABasicAnimation.init(keyPath: "position.y")
        animationBottom.toValue = bottomMenuView.frame.origin.y + bottomMenuView.frame.size.height/2
        animationBottom.fromValue = bottomMenuView.frame.origin.y + bottomMenuView.frame.size.height*3/2
        animationBottom.duration = 0.3
        bottomMenuView.layer.add(animationBottom, forKey: "showBottom")
    }
    
    func hideAnimation() {
        self.clickToHide()
    }
    
    func setTitle(title:String) {
        var title = title
        title = title.replacingOccurrences(of: ".txt", with: "")
        title = title.replacingOccurrences(of: " ", with: "")
        if title.count > 5 {
            title = String(title.prefix(5))+"..."
        }
        titleLabel.text = title
    }
    
    private func setupSubViews() {
        addSubview(topMenuView)
        addSubview(bottomMenuView)
        topMenuView.addSubview(backButton)
        topMenuView.addSubview(moreButton)
        topMenuView.addSubview(titleLabel)
        bottomMenuView.addSubview(catalogButton)
        bottomMenuView.addSubview(catalogLabel)
        bottomMenuView.addSubview(settingsButton)
        bottomMenuView.addSubview(settingsLabel)
        bottomMenuView.addSubview(progressButton)
        bottomMenuView.addSubview(progressLabel)
        
        topMenuView.snp.makeConstraints { make in
            make.top.left.right.equalTo(self)
            make.bottom.equalTo(self.snp.top).offset(100)
        }
        bottomMenuView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            make.top.equalTo(self.snp.bottom).offset(-100)
        }
        backButton.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.left.equalTo(self).offset(15)
            make.top.equalTo(self).offset(60)
        }
        moreButton.snp.makeConstraints { make in
            make.size.equalTo(35)
            make.right.equalTo(self).offset(-20)
            make.top.equalTo(self).offset(50)
        }
        catalogButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 30, height: 30))
            make.top.equalTo(bottomMenuView).offset(5)
            make.left.equalTo(bottomMenuView).offset(50)
        }
        catalogLabel.snp.makeConstraints { make in
            make.centerX.equalTo(catalogButton)
            make.top.equalTo(catalogButton.snp.bottom)
        }
        settingsButton.snp.makeConstraints { make in
            make.size.equalTo(30)
            make.top.equalTo(bottomMenuView).offset(5)
            make.right.equalTo(bottomMenuView).offset(-50)
        }
        settingsLabel.snp.makeConstraints { make in
            make.centerX.equalTo(settingsButton)
            make.top.equalTo(settingsButton.snp.bottom)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(topMenuView)
            make.bottom.equalTo(topMenuView).offset(-10)
        }
        progressButton.snp.makeConstraints { make in
            make.centerY.equalTo(catalogButton)
            make.centerX.equalTo(bottomMenuView)
        }
        progressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(catalogLabel)
            make.centerX.equalTo(bottomMenuView)
        }
    }
    
    private func addGesture() {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(self.clickToHide))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    @objc private func clickToHide() {
        let animationTop = CABasicAnimation.init(keyPath: "position.y")
        animationTop.fromValue = topMenuView.frame.origin.y + topMenuView.frame.size.height/2
        animationTop.toValue = topMenuView.frame.origin.y - topMenuView.frame.size.height/2
        animationTop.duration = 0.3
        animationTop.fillMode = .forwards
        animationTop.isRemovedOnCompletion = false
        topMenuView.layer.add(animationTop, forKey: "dismissTop")
        
        let animationBottom = CABasicAnimation.init(keyPath: "position.y")
        animationBottom.fromValue = bottomMenuView.frame.origin.y + bottomMenuView.frame.size.height/2
        animationBottom.toValue = bottomMenuView.frame.origin.y + bottomMenuView.frame.size.height*3/2
        animationBottom.duration = 0.3
        animationBottom.fillMode = .forwards
        animationBottom.isRemovedOnCompletion = false
        animationBottom.finishBlock = {[weak self] anim, finish in
            self?.removeFromSuperview()
            //此处有个野指针崩溃
//            completion?()
        }
        bottomMenuView.layer.add(animationBottom, forKey: "dismissBottom")
    }
    
    @objc private func backClickAction() {
        delegate?.menuView(didClickBack: self)
    }
    
    @objc private func catalogClickAction() {
        delegate?.menuView(didClickCatalog: self)
    }
    
    @objc private func progressClckAction() {
        delegate?.menuView(didClickProgress: self)
    }
    
    @objc private func settingsClickAction() {
        let view = SettingsView.init(frame: self.frame)
        view.delegate = self
        addSubview(view)
        view.showAnimation()
        topMenuViewHide()
    }
    
    private func topMenuViewHide() {
        let animationTop = CABasicAnimation.init(keyPath: "position.y")
        animationTop.fromValue = topMenuView.frame.origin.y + topMenuView.frame.size.height/2
        animationTop.toValue = topMenuView.frame.origin.y - topMenuView.frame.size.height/2
        animationTop.duration = 0.3
        animationTop.fillMode = .forwards
        animationTop.isRemovedOnCompletion = false
        animationTop.finishBlock = {[weak self](anim, finish) in
            self?.topMenuView.removeFromSuperview()
            self?.bottomMenuView.removeFromSuperview()
        }
        topMenuView.layer.add(animationTop, forKey: "dismissTop")
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        if topMenuView.frame.contains(point) || bottomMenuView.frame.contains(point) {
            return false
        }
        return true
    }
    
    func settingsView(_ view: SettingsView, didChangeFont font: UIFont) {
        delegate?.menuView(self, didChangeFont: font)
    }
}

protocol SettingsViewDelegate:AnyObject {
    func settingsView(_ view:SettingsView, didChangeFont font:UIFont)
}

class SettingsView:UIView, UIGestureRecognizerDelegate{
    weak open var delegate:SettingsViewDelegate? = nil
    lazy var containerView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    lazy var fontSizeLabel:UILabel = {
        let label = UILabel()
        label.text = "字号"
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        return label
    }()
    lazy var curFontLabel:UILabel = {
        let label = UILabel()
        label.text = "\(Int(SDZReadConfig.shared.font.pointSize))"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    lazy var fontIncreaseButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("A+", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.textAlignment = .center
        btn.backgroundColor = UIColor(hexString: "#e7f0f4")
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 30.0/2
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(self.fontInscreaseAction), for: .touchUpInside)
        return btn
    }()
    lazy var fontDecreaseButton:UIButton = {
        let btn = UIButton()
        btn.setTitle("A-", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.textAlignment = .center
        btn.backgroundColor = UIColor(hexString: "#e7f0f4")
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 30.0/2
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.addTarget(self, action: #selector(self.fontDecreaseAction), for: .touchUpInside)
        return btn
    }()
    lazy var fontContainerView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#e7f0f4")
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 30.0/2
        return view
    }()
    lazy var fontNameLabel:UILabel = {
        let label = UILabel()
        label.text = "系统黑体"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    lazy var fontNameImageView:UIImageView = {
        let view = UIImageView.init(image: UIImage.init(named: "right_black"))
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        addGestre()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAnimation() {
        layoutIfNeeded()
        let animation = CABasicAnimation.init(keyPath: "position.y")
        animation.toValue = containerView.frame.origin.y + containerView.frame.size.height/2
        animation.fromValue = containerView.frame.origin.y + containerView.frame.size.height*3/2
        animation.duration = 0.3
        containerView.layer.add(animation, forKey: "show")
    }
    
    private func setupSubviews() {
        addSubview(containerView)
        containerView.addSubview(fontSizeLabel)
        containerView.addSubview(fontIncreaseButton)
        containerView.addSubview(curFontLabel)
        containerView.addSubview(fontDecreaseButton)
        containerView.addSubview(fontContainerView)
        fontContainerView.addSubview(fontNameLabel)
        fontContainerView.addSubview(fontNameImageView)
        
        containerView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(self)
            make.top.equalTo(self.snp.bottom).offset(-300)
        }
        fontSizeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(fontIncreaseButton)
            make.top.equalTo(containerView).offset(30)
            make.left.equalTo(containerView).offset(30)
        }
        fontIncreaseButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 80, height: 30))
            make.centerY.equalTo(fontSizeLabel)
            make.left.equalTo(fontDecreaseButton.snp.right).offset(45)
        }
        curFontLabel.snp.makeConstraints { make in
            make.centerY.equalTo(fontSizeLabel)
            make.left.equalTo(fontDecreaseButton.snp.right).offset(15)
        }
        fontDecreaseButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 80, height: 30))
            make.centerY.equalTo(fontSizeLabel)
            make.left.equalTo(fontSizeLabel.snp.right).offset(15)
        }
        fontContainerView.snp.makeConstraints { make in
            make.size.equalTo(CGSize.init(width: 80, height: 30))
            make.right.equalTo(containerView).offset(-30)
            make.centerY.equalTo(fontSizeLabel)
        }
        fontNameLabel.snp.makeConstraints { make in
            make.left.equalTo(fontContainerView).offset(10)
            make.centerY.equalTo(fontContainerView)
        }
        fontNameImageView.snp.makeConstraints { make in
            make.size.equalTo(15)
            make.right.equalTo(fontContainerView).offset(-5)
            make.centerY.equalTo(fontContainerView)
        }
    }
    
    private func addGestre() {
        //拦截手势
        let tap = UITapGestureRecognizer()
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        addGestureRecognizer(tap)
        
        let hideTap = UITapGestureRecognizer()
        hideTap.numberOfTapsRequired = 1
        hideTap.numberOfTouchesRequired = 1
        hideTap.addTarget(self, action: #selector(self.hideClickAction))
        hideTap.delegate = self
        addGestureRecognizer(hideTap)
    }
    
    @objc func hideClickAction() {
        let animation = CABasicAnimation.init(keyPath: "position.y")
        animation.fromValue = containerView.frame.origin.y + containerView.frame.size.height/2
        animation.toValue = containerView.frame.origin.y + containerView.frame.size.height*3/2
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.duration = 0.3
        animation.finishBlock = {[weak self](anim, finish) in
            self?.superview?.removeFromSuperview()
        }
        containerView.layer.add(animation, forKey: "dismiss")
    }
    
    @objc func fontInscreaseAction() {
        if SDZReadConfig.shared.font.pointSize >= 24.0 {
            return
        }
        let font = UIFont.systemFont(ofSize: SDZReadConfig.shared.font.pointSize + 2.0)
        curFontLabel.text = "\(Int(font.pointSize))"
        delegate?.settingsView(self, didChangeFont: font)
    }
    
    @objc func fontDecreaseAction() {
        if SDZReadConfig.shared.font.pointSize <= 14.0 {
            return
        }
        let font = UIFont.systemFont(ofSize: SDZReadConfig.shared.font.pointSize - 2.0)
        curFontLabel.text = "\(Int(font.pointSize))"
        delegate?.settingsView(self, didChangeFont: font)
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        if !containerView.frame.contains(point) {
            return true
        }
        return false
    }
}

protocol ProgressViewDelegate:AnyObject {
    func progressView(_ view:ProgressView, didChangeProgressValue value:Double)
}

class ProgressView:UIView, UIGestureRecognizerDelegate {
    
    weak open var delegate:ProgressViewDelegate? = nil
    private var _progress:Double = 0
    
    var progress:Double {
        set {
            _progress = newValue
            progressSliderView.value = Float(newValue)
            progressLabel.text = "\(newValue)%"
        }
        get {
            return _progress
        }
    }
    
    private lazy var containerView:UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var leftButton:UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage.init(named: "back_black"), for: .normal)
        return btn
    }()
    
    private lazy var rightButton:UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage.init(named: "right_black"), for: .normal)
        return btn
    }()
    
    private lazy var progressLabel:UILabel = {
       let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.text = "12.13%"
        label.textColor = UIColor.black
        label.textAlignment = .center
        return label
    }()
    
    private lazy var progressSliderView:UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 100.0
        slider.value = 0
        slider.thumbTintColor = UIColor.init(hexString: "#323b40")
        slider.minimumTrackTintColor = UIColor.init(hexString: "#323b40")
        slider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .touchUpInside)
        return slider
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        addGesture()
    }
    
    func showAnimation() {
        layoutIfNeeded()
        let animation = CABasicAnimation.init(keyPath: "position.y")
        animation.fromValue = containerView.frame.origin.y + containerView.frame.size.height*3/2
        animation.toValue = containerView.frame.origin.y + containerView.frame.size.height/2
        animation.duration = 0.3
        containerView.layer.add(animation, forKey: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(containerView)
        containerView.addSubview(progressSliderView)
        containerView.addSubview(leftButton)
        containerView.addSubview(rightButton)
        containerView.addSubview(progressLabel)
        
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.top.equalTo(self.snp.bottom).offset(-110)
        }
        progressSliderView.snp.makeConstraints { make in
            make.left.equalTo(containerView).offset(65)
            make.right.equalTo(containerView).offset(-65)
            make.top.equalTo(containerView).offset(30)
            make.bottom.equalTo(containerView).offset(-30)
        }
        leftButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.equalTo(progressSliderView)
            make.left.equalTo(containerView).offset(20)
        }
        rightButton.snp.makeConstraints { make in
            make.size.equalTo(50)
            make.centerY.equalTo(progressSliderView)
            make.right.equalTo(containerView).offset(-20)
        }
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.bottom.equalTo(progressSliderView.snp.top)
        }
    }
    
    private func addGesture() {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(self.backAction))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    private func dismissAnimation() {
        let animation = CABasicAnimation.init(keyPath: "position.y")
        animation.toValue = containerView.frame.origin.y + containerView.frame.size.height*3/2
        animation.fromValue = containerView.frame.origin.y + containerView.frame.size.height/2
        animation.duration = 0.3
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.finishBlock = {[weak self](animation, finish) in
            guard let self = self else {
                return
            }
            self.removeFromSuperview()
        }
        containerView.layer.add(animation, forKey: nil)
    }
    
    @objc private func backAction() {
        dismissAnimation()
    }
    
    @objc private func sliderValueDidChange() {
        delegate?.progressView(self, didChangeProgressValue: Double(progressSliderView.value))
        let str = String(format: "%.2f", progressSliderView.value)
        progressLabel.text = str+"%"
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        if !containerView.frame.contains(point) {
            return true
        }
        return false
    }
    
}
