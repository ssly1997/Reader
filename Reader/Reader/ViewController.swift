//
//  ViewController.swift
//  Reader
//
//  Created by 李方长 on 2021/12/15.
//

import UIKit

class ViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(notifi:)), name: NSNotification.Name("receive.new"), object: nil)
        self.view.backgroundColor = UIColor.green
        testFunc()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.present(bookShelfVC, animated: true, completion: nil)
    }
    
    func testFunc() {
        let url = Bundle.main.url(forResource: "雪中悍刀行", withExtension: "txt")!
        DispatchQueue.init(label: "com.sdz").async {
            do {
                let readModel = try SDZReadModel.getReadModel(url: url)
                DispatchQueue.main.async {
                    let pageVC = ReadPageViewController()
                    pageVC.readModel = readModel
                    pageVC.modalPresentationStyle = .fullScreen
                    self.bookShelfVC
                        .present(pageVC, animated: true, completion: nil)
                }
            }
            catch {
                print(error)
            }
        }
    }
    
    lazy var bookShelfVC:BookShelfViewController = {
        let bookShelfVC = BookShelfViewController()
        bookShelfVC.modalPresentationStyle = .fullScreen
        bookShelfVC.view.backgroundColor = UIColor.yellow
        return bookShelfVC
    }()
    
    @objc func receiveNotification(notifi : Notification) {
        guard let userInfo = notifi.userInfo else {
            return
        }
        print("🇨🇳打开一本新书: \(userInfo.keys.first!)")
        for key in userInfo.keys {
            let url = userInfo[key]
            DispatchQueue.init(label: "com.sdz").async {
                do {
                    guard let readModel = try SDZReadModel.getReadModel(url: url as! URL) else {
                        print("转换失败")
                        return
                    }
                    SDZFileUtilites.deleteFile(url: url as! URL)
                    readModel.name = (key as! String)
                    DispatchQueue.main.async {
                        let pageVC = ReadPageViewController()
                        pageVC.readModel = readModel
                        pageVC.modalPresentationStyle = .fullScreen
                        self.bookShelfVC.present(pageVC, animated: true, completion: nil)
                    }
                }
                catch {
                    assert(false, "error")
                }
            }
        }
    }
}

func printTime() {
    let date = Date()
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "🇨🇳yyy-MM-dd' at 'HH:mm:ss.SSS"
    let strNowTime = timeFormatter.string(from: date) as String
    print(strNowTime)
}
