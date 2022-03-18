//
//  BookShelfViewController.swift
//  Reader
//
//  Created by 李方长 on 2021/12/25.
//

import Foundation
import UIKit

class BookShelfViewController:UIViewController , UICollectionViewDelegate, UICollectionViewDataSource, SDZBookShelfCollectionViewCellDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.booksDidUpdate), name: NSNotification.Name("com.books.update"), object: nil)
        self.view.addSubview(bookCollectionView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    lazy var bookCollectionView:UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100 , height: 160)
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 1
        let collectionView = UICollectionView.init(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(SDZBookShelfCollectionViewCell.self, forCellWithReuseIdentifier: "SDZBookShelfCollectionViewCell")
        return collectionView
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SDZReadConfig.shared.books.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:SDZBookShelfCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "SDZBookShelfCollectionViewCell", for: indexPath) as! SDZBookShelfCollectionViewCell
        cell.configCell(title: SDZReadConfig.shared.books[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func bookShelfCell(_ cell: SDZBookShelfCollectionViewCell, didClick title: String) {
        do {
            let readModel = try SDZReadModel.getReadModel(fileName: title)
            let readVC = ReadPageViewController()
            readVC.readModel = readModel
            readVC.modalPresentationStyle = .fullScreen
            self.present(readVC, animated: true, completion: nil)
        }
        catch {
            assert(false, "error!")
        }
    }
    
    @objc func booksDidUpdate() {
        DispatchQueue.main.async {
            self.bookCollectionView.reloadData()
        }
    }
}
