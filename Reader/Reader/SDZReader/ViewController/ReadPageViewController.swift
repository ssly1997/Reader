//
//  ReadPageViewController.swift
//  Reader
//
//  Created by 李方长 on 2021/12/26.
//

import Foundation
import UIKit

let kScreenRect = UIScreen.main.bounds
let kNavigationBarW:Double = 20.0
let kNavigationBarTop:Double = 45.0
let kNavigationBarBottom:Double = 120.0
let kReadRect = CGRect.init(origin: CGPoint.init(x: kScreenRect.origin.x + kNavigationBarW, y: kScreenRect.origin.y + kNavigationBarBottom), size: CGSize.init(width: kScreenRect.size.width - 2 * kNavigationBarW, height: kScreenRect.size.height - kNavigationBarTop - kNavigationBarBottom))


class ReadPageViewController:UIViewController & UIPageViewControllerDelegate & UIPageViewControllerDataSource & SDZCatalogViewControllerDelegate, UIGestureRecognizerDelegate, MenuViewDelegate, ProgressViewDelegate {
    lazy var pageVC:UIPageViewController = {
        let pageVC = UIPageViewController.init(transitionStyle: .pageCurl, navigationOrientation: .horizontal, options: nil)
        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.setViewControllers([self.readView(chapter: currentChapterIndex, page: currentPageIndex)], direction: .forward, animated: true, completion: nil)
        self.view.addSubview(pageVC.view)
        return pageVC
    }()
    var readModel:SDZReadModel? = nil
    var currentPage:ReadViewController? = nil
    var currentChapterIndex = 0
    var currentPageIndex = 0
    var pageDown = true
    var menuView:MenuView? = nil
    var timer:Timer? = nil
    let pageQueue = DispatchQueue.init(label: "com.page.sdz")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 先拿到阅读进度的章节
        self.currentChapterIndex = self.getReadProgress().chapter
        separateCurPagesAsync { [weak self] in
            guard let self = self else {
                return
            }
            //将当前章节分好页之后根据保存的offset计算出当前页
            let (chapter, page) = self.getReadProgress()
            self.currentChapterIndex = chapter
            self.currentPageIndex = page
            self.addChild(self.pageVC)
            self.addGesture()
            self.addTimer()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var pageIndex = currentPageIndex
        var chapterIndex = currentChapterIndex
        if pageIndex > 0 {
            pageIndex -= 1
        } else {
            if chapterIndex > 0 {
                chapterIndex -= 1
                if readModel!.chapters[chapterIndex].pages.isEmpty {
                    SDZReadUtilites.separatePages(pages: &readModel!.chapters[chapterIndex].pages, chapter: readModel!.chapters[chapterIndex])
                    print("🇨🇳 同步分页完成")
                }
                pageIndex = readModel!.chapters[chapterIndex].pages.count - 1
                self.preSeparatePagesAsync(chapter: chapterIndex-1)
            } else {
                return nil
            }
        }
        pageDown = false
        return readView(chapter: chapterIndex, page: pageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var pageIndex = currentPageIndex
        var chapterIndex = currentChapterIndex
        if pageIndex < readModel!.chapters[chapterIndex].pages.count - 1 {
            pageIndex += 1
        } else {
            if chapterIndex < readModel!.chapters.count - 1 {
                chapterIndex += 1
                pageIndex = 0
                if readModel!.chapters[chapterIndex].pages.isEmpty {
                    SDZReadUtilites.separatePages(pages: &readModel!.chapters[chapterIndex].pages, chapter: readModel!.chapters[chapterIndex])
                    print("🇨🇳 同步分页完成")
                }
                self.preSeparatePagesAsync(chapter: chapterIndex + 1)
            } else {
                return nil
            }
        }
        pageDown = true
        return readView(chapter: chapterIndex, page: pageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        //开始翻页的时候更新数据源
        if pageDown {
            let (chapter, page) = pageDown(chapter: currentChapterIndex, page: currentPageIndex)
            currentChapterIndex = chapter
            currentPageIndex = page
        } else {
            let (chapter, page) = pageUp(chapter: currentChapterIndex, page: currentPageIndex)
            currentChapterIndex = chapter
            currentPageIndex = page
        }
        saveReadProgress(chapter: currentChapterIndex, page: currentPageIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        //如果翻页被打断将数据源重置
        if !completed {
            if pageDown {
                let (chapter, page) = pageUp(chapter: currentChapterIndex, page: currentPageIndex)
                currentChapterIndex = chapter
                currentPageIndex = page
            } else {
                let (chapter, page) = pageDown(chapter: currentChapterIndex, page: currentPageIndex)
                currentChapterIndex = chapter
                currentPageIndex = page
            }
            saveReadProgress(chapter: currentChapterIndex, page: currentPageIndex)
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: view)
        let rect = CGRect.init(x: (view.frame.size.width - 100.0)/CGFloat(2.0), y: (view.frame.size.height-600.0)/CGFloat(2.0), width: 100, height: 600)
        if rect.contains(point) {
            return true
        }
        return false
    }
    
    func catalog(catalog: SDZCatalogViewController, didSelectChapter chapter: Int) {
        if readModel!.chapters[chapter].pages.isEmpty {
            pageQueue.async {
                SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[chapter].pages, chapter: self.readModel!.chapters[chapter])
                DispatchQueue.main.async {
                    self.currentPage?.chapterTitle = self.readModel?.chapters[chapter].title
                    if self.readModel!.type == .txt {
                        self.currentPage?.content = self.readModel?.chapters[chapter].pages.first?.content
                    } else if self.readModel!.type == .epub {
                        self.currentPage?.attContent = self.readModel?.chapters[chapter].pages.first?.attContent
                    } else {
                        assert(false, "error")
                    }
                    self.currentPage?.progress = self.calReadProgress(chapter: chapter, page: 0)
                    self.currentChapterIndex = chapter
                    self.currentPageIndex = 0
                    self.saveReadProgress(chapter: self.currentChapterIndex, page: self.currentPageIndex)
                    self.preSeparatePagesAsync(chapter: self.currentChapterIndex-1)
                    self.preSeparatePagesAsync(chapter: self.currentChapterIndex+1)
                }
            }
        } else {
            if self.readModel!.type == .txt {
                self.currentPage?.content = self.readModel?.chapters[chapter].pages.first?.content
            } else if self.readModel!.type == .epub {
                self.currentPage?.attContent = self.readModel?.chapters[chapter].pages.first?.attContent
            } else {
                assert(false, "error")
            }
            self.currentChapterIndex = chapter
            self.currentPageIndex = 0
            saveReadProgress(chapter: currentChapterIndex, page: currentPageIndex)
            self.preSeparatePagesAsync(chapter: currentChapterIndex-1)
            self.preSeparatePagesAsync(chapter: currentChapterIndex+1)
        }
    }
    
    func menuView(didClickBack view: MenuView) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func menuView(didClickCatalog view: MenuView) {
        self.menuView?.removeFromSuperview()
        self.menuView = nil
        let catalogVC = SDZCatalogViewController()
        catalogVC.readModel = readModel
        catalogVC.delegate = self
        catalogVC.currentChapter = currentChapterIndex
        catalogVC.modalPresentationStyle = .fullScreen
        // vc右侧弹出
        let transition = CATransition();
        transition.duration = 0.3;
        transition.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        transition.type = .push;
        transition.subtype = .fromRight;
        self.view.window?.layer.add(transition, forKey: nil)
        self.present(catalogVC, animated: false, completion: nil)
    }
    
    func menuView(didClickProgress view: MenuView) {
//        self.menuView?.hideAnimation(completion: {[weak self] in
//            guard let self = self else {
//                return
//            } <--这种写法导致了野指针崩溃 view被系统回收后依然调用了下面的代码
//            self?.menuView = nil
//        })
        // sdztodo  这里因为block野指针放弃了将menu置为nil
        self.menuView?.hideAnimation()
        self.menuView = nil
        let progressView = ProgressView.init(frame: self.view.frame)
        let progressStr = calReadProgress(chapter: currentChapterIndex, page: currentPageIndex)
        progressView.progress = Double(progressStr.replacingOccurrences(of: "%", with: "")) ?? 0.0
        progressView.delegate = self
        self.view.addSubview(progressView)
        progressView.showAnimation()
    }
    
    func menuView(_ view: MenuView, didChangeFont font: UIFont) {
        //更新系统字号(保存在UserDefaults中)
        SDZReadConfig.shared.font = font
        //记录原本的阅读进度(当前页之前的字数)
        var offset = 0
        let type = readModel!.type
        for page in readModel!.chapters[currentChapterIndex].pages {
            if currentPageIndex > page.index {
                if type == .txt {
                    offset += page.content.count
                } else if type == .epub {
                    offset += page.attContent.length
                } else {
                    assert(false, "error")
                }
            } else {
                break
            }
        }
        //删除原本的分页信息
        for chapter in readModel!.chapters {
            chapter.pages.removeAll()
        }
        //按新字号重新分页
        separateCurPagesAsync { [weak self] in
            guard let self = self else {
                return
            }
            //重新定位新页码
            var newOffset = 0
            var newPageIndex = 0
            let type = self.readModel!.type
            for page in self.readModel!.chapters[self.currentChapterIndex].pages {
                if type == .txt {
                    newOffset += page.content.count
                } else if type == .epub {
                    newOffset += page.attContent.length
                } else {
                    assert(false, "error")
                }
                if newOffset > offset {
                    break
                }
                newPageIndex += 1
            }
            self.currentPageIndex = newPageIndex
            if self.readModel?.type == .txt {
                self.currentPage?.content = self.readModel!.chapters[self.currentChapterIndex].pages[self.currentPageIndex].content
            } else if self.readModel?.type == .epub {
                self.currentPage?.attContent = self.readModel!.chapters[self.currentChapterIndex].pages[self.currentPageIndex].attContent
            }
            self.saveReadProgress(chapter: self.currentChapterIndex, page: self.currentPageIndex)
        }
    }
    // sdztodo 滑动逻辑还是有点问题 有时候不切页 滑动page的计算也不对
    func progressView(_ view: ProgressView, didChangeProgressValue value: Double) {
        let (chapter, page) = calReadProgress(value: value)
        print("哈哈 value:\(value) chapter:\(chapter), page:\(page)")
        if readModel!.chapters[chapter].pages.isEmpty {
            pageQueue.async {
                SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[chapter].pages, chapter: self.readModel!.chapters[chapter])
                DispatchQueue.main.async {
                    self.currentPage?.chapterTitle = self.readModel?.chapters[chapter].title
                    self.currentPage?.content = self.readModel?.chapters[chapter].pages.first?.content
                    self.currentPage?.progress = self.calReadProgress(chapter: chapter, page: page)
                    self.currentChapterIndex = chapter
                    self.currentPageIndex = page
                    self.saveReadProgress(chapter: self.currentChapterIndex, page: self.currentPageIndex)
                    self.preSeparatePagesAsync(chapter: self.currentChapterIndex-1)
                    self.preSeparatePagesAsync(chapter: self.currentChapterIndex+1)
                }
            }
        } else {
            self.currentPage?.content = self.readModel?.chapters[chapter].pages[page].content
            self.currentChapterIndex = chapter
            self.currentPageIndex = page
            saveReadProgress(chapter: currentChapterIndex, page: currentPageIndex)
            self.preSeparatePagesAsync(chapter: currentChapterIndex-1)
            self.preSeparatePagesAsync(chapter: currentChapterIndex+1)
        }
    }
    
    private func separateCurPagesAsync(_ completion:@escaping ()->Void) {
        pageQueue.async {
            SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[self.currentChapterIndex].pages , chapter: self.readModel!.chapters[self.currentChapterIndex])
            DispatchQueue.main.async {
                print("🇨🇳 \(self.currentChapterIndex)章 异步分页完成")
                completion()
            }
            if self.readModel!.chapters.count > self.currentChapterIndex+1 {
                SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[self.currentChapterIndex+1].pages, chapter: self.readModel!.chapters[self.currentChapterIndex+1])
                print("🇨🇳 \(self.currentChapterIndex+1)章 异步分页完成")
            }
            if self.currentChapterIndex > 0 {
                SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[self.currentChapterIndex-1].pages, chapter: self.readModel!.chapters[self.currentChapterIndex-1])
                print("🇨🇳 \(self.currentChapterIndex-1)章 异步分页完成")
            }
        }
    }
    
    private func readView(chapter:Int, page:Int) -> ReadViewController {
        currentPage = ReadViewController()
        if readModel!.type == .txt {
            currentPage?.content = self.readModel?.chapters[chapter].pages[page].content
        } else if readModel!.type == .epub {
            currentPage?.attContent = self.readModel?.chapters[chapter].pages[page].attContent
        } else {
            assert(false, "error")
        }
        currentPage?.chapterTitle = self.readModel?.chapters[chapter].title
        currentPage?.progress = calReadProgress(chapter: chapter, page: page)
        currentPage?.time = getCurTime()
        print("🇨🇳 progress： \(currentPage!.progress!)")
        return currentPage!
    }
    
    private func calReadProgress(value:Double) -> (chapter:Int, page:Int) {
        let value = value/100.0
        var chapterIndex = 0, pageIndex = 0
        for i in 0..<readModel!.chapters.count {
            if readModel!.chapters[i].progress >= value {
                chapterIndex = i > 0 ? i - 1 : 0
                break
            }
        }
        let preChapterProgress = readModel!.chapters[chapterIndex].progress
        let curChapterProgress = chapterIndex < readModel!.chapters.count ? self.readModel!.chapters[chapterIndex + 1].progress : 1.0
        for page in readModel!.chapters[chapterIndex].pages {
            if page.progress * (curChapterProgress - preChapterProgress) + preChapterProgress >= value {
                pageIndex = page.index
                break
            }
        }
        return (chapterIndex, pageIndex)
    }
    
    private func calReadProgress(chapter:Int, page:Int) -> String {
        var preChapterProgress = 0.0
        if chapter > 0 {
            preChapterProgress = self.readModel!.chapters[chapter-1].progress
        }
        let curChapterProgress = self.readModel!.chapters[chapter].progress
        if readModel!.chapters[chapter].pages.isEmpty {
            SDZReadUtilites.separatePages(pages: &readModel!.chapters[chapter].pages, chapter: readModel!.chapters[chapter])
        }
        let curPageProgress = self.readModel!.chapters[chapter].pages[page].progress
        let progressStr = String(format: "%.2f", (preChapterProgress + (curChapterProgress - preChapterProgress)*curPageProgress) * 100)
        return progressStr+"%"
    }
    
    private func pageDown(chapter:Int, page:Int) -> (newChapter:Int, newPage:Int) {
        var newPage = page
        var newChapter = chapter
        if page < readModel!.chapters[chapter].pages.count - 1 {
            newPage += 1
        } else {
            if newChapter < readModel!.chapters.count - 1 {
                newChapter += 1
                newPage = 0
            }
        }
        return (newChapter, newPage)
    }
    
    private func pageUp(chapter:Int, page:Int) -> (newChapter:Int, newPage:Int) {
        var newPage = page
        var newChapter = chapter
        if page > 0 {
            newPage -= 1
        } else {
            if newChapter > 0 {
                newChapter -= 1
                newPage = readModel!.chapters[newChapter].pages.count - 1
            }
        }
        return (newChapter, newPage)
    }
    
    @objc func menuAction() {
        let menu = MenuView.init(frame: self.view.frame)
        self.menuView = menu
        menu.delegate = self
        menu.setTitle(title: readModel!.name!)
        self.view.addSubview(menu)
        menu.showAnimation()
    }
    
    private func addGesture() {
        let tap = UITapGestureRecognizer()
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        tap.addTarget(self, action: #selector(self.menuAction))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    private func addTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) {[weak self] timer in
            DispatchQueue.main.async {
                self?.currentPage?.time = self?.getCurTime()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func getCurTime() -> String {
        let date = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let strNowTime = timeFormatter.string(from: date) as String
        return strNowTime
    }
    
    private func preSeparatePagesAsync(chapter:Int) {
        self.pageQueue.async {
            if chapter >= 0 && chapter < self.readModel!.chapters.count && self.readModel!.chapters[chapter].pages.isEmpty {
                SDZReadUtilites.separatePages(pages: &self.readModel!.chapters[chapter].pages, chapter: self.readModel!.chapters[chapter])
                print("🇨🇳异步分页完成 \(chapter) \(self.readModel!.chapters[chapter].pages.count), cur:\(self.currentChapterIndex)")
            }
        }
    }
    
    private func saveReadProgress(chapter:Int, page:Int) {
        let offset = calCurPageOffset(chapter: chapter, page: page)
        let userDeafult = UserDefaults.standard
        userDeafult.set(chapter, forKey: "\(self.readModel?.readHash ?? "key")"+"curChapter")
        userDeafult.set(offset, forKey: "\(self.readModel?.readHash ?? "key")"+"curOffset")
        print("🇨🇳chapter:\(chapter), page:\(page), offset:\(offset)")
        userDeafult.synchronize()
    }
    
    private func calCurPageOffset(chapter:Int, page:Int) -> Int {
        var offset = 0
        for i in 0...page {
            if readModel!.type == .txt {
                offset += readModel!.chapters[chapter].pages[i].content.count
            } else if readModel!.type == .epub {
                offset += readModel!.chapters[chapter].pages[i].attContent.length
            } else {
                assert(false, "error")
            }
        }
        return offset
    }
    
    private func getReadProgress() -> (chapter:Int, page:Int) {
        let userDeafult = UserDefaults.standard
        let chapter = userDeafult.integer(forKey: "\(self.readModel?.readHash ?? "key")"+"curChapter")
        let offset = userDeafult.integer(forKey: "\(self.readModel?.readHash ?? "key")"+"curOffset")
        var newOffset = 0
        var newPageIndex = 0
        for page in self.readModel!.chapters[self.currentChapterIndex].pages {
            if readModel!.type == .txt {
                newOffset += page.content.count
            } else if readModel!.type == .epub {
                newOffset += page.attContent.length
            }
            if newOffset > offset {
                break
            }
            newPageIndex += 1
        }
        newPageIndex -= 1
        newPageIndex = newPageIndex < 0 ? 0 : newPageIndex
        return (chapter, newPageIndex)
    }
}
