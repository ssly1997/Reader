//
//  CatalogViewController.swift
//  Reader
//
//  Created by 李方长 on 2021/12/26.
//

import Foundation
import UIKit

protocol SDZCatalogViewControllerDelegate:AnyObject {
    func catalog(catalog:SDZCatalogViewController, didSelectChapter chapter:Int)
}

class SDZCatalogViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, SDZCatalogTableViewCellDelegate {
    
    weak open var delegate:SDZCatalogViewControllerDelegate? = nil
    var readModel:SDZReadModel? = nil
    var currentChapter = 0
    
    lazy var catalogTagLabel:UILabel = {
        let label = UILabel()
        label.text = "目录"
        label.textColor = UIColor.init(hexString: "#149edd")
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    lazy var bookMarkTagLabel:UILabel = {
        let label = UILabel()
        label.text = "书签"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.init(hexString: "#676b6d")
        label.alpha = 0.7
        return label
    }()
    lazy var ideaTagLabel:UILabel = {
        let label = UILabel()
        label.text = "想法"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.init(hexString: "#676b6d")
        label.alpha = 0.7
        return label
    }()
    lazy var backButton:UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage.init(named: "back_black"), for: .normal)
        btn.addTarget(self, action: #selector(self.backClickACtion), for: .touchUpInside)
        return btn
    }()
    
    lazy var tableView = { () -> UITableView in
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(SDZCatalogTableViewCell.self, forCellReuseIdentifier: "SDZCatalogTableViewCell")
        view.backgroundColor = UIColor.white
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        setupSubviews()
        let maxHeight = UIScreen.main.bounds.height - kNavigationBarTop
        self.tableView.setContentOffset(CGPoint.init(x: 0, y: 44 * currentChapter - Int(maxHeight)/2), animated: true)
    }
    
    // MARK: Private
    private func setupSubviews() {
        self.view.addSubview(tableView)
        self.view.addSubview(backButton)
        self.view.addSubview(catalogTagLabel)
        self.view.addSubview(bookMarkTagLabel)
        self.view.addSubview(ideaTagLabel)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(100)
            make.left.right.bottom.equalTo(self.view)
        }
        backButton.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.left.equalTo(self.view).offset(20)
            make.bottom.equalTo(tableView.snp.top).offset(-10)
        }
        catalogTagLabel.snp.makeConstraints { make in
            make.right.equalTo(bookMarkTagLabel.snp.left).offset(-10)
            make.centerY.equalTo(bookMarkTagLabel)
        }
        bookMarkTagLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(tableView.snp.top).offset(-10)
        }
        ideaTagLabel.snp.makeConstraints { make in
            make.centerY.equalTo(bookMarkTagLabel)
            make.left.equalTo(bookMarkTagLabel.snp.right).offset(10)
        }
    }
    
    private func dismissFromLeft() {
        let transition = CATransition();
        transition.duration = 0.3;
        transition.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        transition.type = .push;
        transition.subtype = .fromLeft;
        self.view.window?.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: nil)
    }
    
    @objc private func backClickACtion() {
        dismissFromLeft()
    }
    
    //MARK: tableView DataSource
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return readModel?.chapters.count ?? 0
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SDZCatalogTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SDZCatalogTableViewCell", for: indexPath) as! SDZCatalogTableViewCell
        cell.config(title: self.readModel?.chapters[indexPath.row].title ?? "默认", index: indexPath.row, sepcial: indexPath.row == self.currentChapter)
        cell.delegate = self
        return cell
    }
    
    // MARK: catalog Delegate
    internal func catalog(catalogCell: SDZCatalogTableViewCell, didSelectChapter chapter: Int) {
        if delegate == nil {
            return
        }
        delegate?.catalog(catalog: self, didSelectChapter: chapter)
        dismissFromLeft()
    }
}
