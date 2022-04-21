//
//  Core.swift
//  Reader
//
//  Created by 李方长 on 2021/12/15.
//

import Foundation
import UIKit

struct SDZReadConfig {
    static var shared = SDZReadConfig()
    private var _font:UIFont

    var books:[String]
    var font:UIFont {
        set {
            _font = newValue
            UserDefaults.standard.set(newValue.pointSize, forKey: "fontSize")
        }
        get {
            return _font
        }
    }
    var fontColor:UIColor
    var lineSpace:CGFloat
    var theme:UIColor
    init() {
        let fontSize = UserDefaults.standard.float(forKey: "fontSize")
        if fontSize != 0 {
            _font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        } else {
            _font = UIFont.systemFont(ofSize: 18)
            UserDefaults.standard.set(18, forKey: "fontSize")
        }
        fontColor = UIColor.black
        lineSpace = 10
        theme = UIColor.white
        books = UserDefaults.standard.array(forKey: "books") as? [String] ?? [String]()
    }
}

class SDZReadParser {
    class func parserTxt(content:String, config:SDZReadConfig, bounds:CGRect) -> CTFrame {
        let attribute = parserAttribute(config: config)
        let attributeStr = NSAttributedString(string: content, attributes: attribute)
        let frameSetter:CTFramesetter = CTFramesetterCreateWithAttributedString(attributeStr)
        let path = CGMutablePath()
        path.addRect(bounds)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange.init(location: 0, length: attributeStr.length), path, nil)
        return frame
    }
    
    class func parserEpub(content:NSAttributedString, bounds:CGRect) -> CTFrame {
        let content = SDZReadUtilites.changeAttStrFont(att: content, fontSize: SDZReadConfig.shared.font.pointSize)
        let frameSetter:CTFramesetter = CTFramesetterCreateWithAttributedString(content)
        let path = CGMutablePath()
        path.addRect(bounds)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange.init(location: 0, length: content.length), path, nil)
        return frame
    }
    
    class fileprivate func parserAttribute(config:SDZReadConfig) -> Dictionary<NSAttributedString.Key, Any> {
        var dic = Dictionary<NSAttributedString.Key, Any>()
        dic[NSAttributedString.Key.foregroundColor] = config.fontColor
        dic[NSAttributedString.Key.font] = config.font
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = config.lineSpace
        paragraphStyle.alignment = .justified
        dic[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        return dic
    }
}

class SDZReadUtilites {
    
    class func separateTxtChapters(chapters:inout [SDZChapterModel], content:String, key:String?) {
        chapters.removeAll()
        let total = Double(content.count)
        let pattern = "第[0-9〇零一二三四五六七八九十百千]*[章回节].*"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = content as NSString
        let matches = regex?.matches(in: content, options: .reportCompletion, range: NSRange.init(location: 0, length: nsString.length))
        guard let matches = matches else {
            return
        }
        var dic = [Int:String]()
        var index = 0
        var start = 0
        var progress = 0.0
        var title = "序幕"
        dic[start] = title
        for match in matches {
            let range = match.range
            let matchString = nsString.substring(with: range) as String
            let chapter = SDZChapterModel.init(index: index, title: title, content: nsString.substring(with: NSRange.init(location: start, length: range.location - start)))
            progress = progress + Double(chapter.content.count)/total
            chapter.progress = progress
            chapters.append(chapter)
            title = matchString
            index += 1
            start = range.lowerBound
            dic[start] = title
        }
        let lastContet = nsString.substring(with: NSRange.init(location: start, length: nsString.length - start))
        let chapter = SDZChapterModel.init(index: index, title: title, content: lastContet)
        chapter.progress = 1.0
        chapters.append(chapter)
    }
    
    class func separatePages(pages:inout [SDZPageModel], chapter:SDZChapterModel) {
        print("😄 分页！")
        pages.removeAll()
        
        var attributeStr:NSAttributedString? = nil
        
        if chapter.type == .txt {
            let attribute = SDZReadParser.parserAttribute(config: SDZReadConfig.shared)
            attributeStr = NSAttributedString(string: chapter.content, attributes: attribute)
        } else if chapter.type == .epub {
            attributeStr = SDZReadUtilites.changeAttStrFont(att: chapter.attContent!, fontSize: SDZReadConfig.shared.font.pointSize)
        }
        
        guard let attributeStr = attributeStr else {
            return
        }
        if attributeStr.length == 0 {
            let page = SDZPageModel.init(index: 0, chapter:chapter, range: NSRange.init(location: 0, length: 0))
            pages.append(page)
            return
        }
       
        let frameSetter:CTFramesetter = CTFramesetterCreateWithAttributedString(attributeStr)
        let total = Double(attributeStr.length)
        
        var textPos = 0
        var pageIndex = 0
        var progress = 0.0
        
        while textPos < attributeStr.length {
            let path = CGPath.init(rect: CGRect.init(x: 0, y: 0, width: kReadRect.width, height: kReadRect.height), transform: nil)
            let frame = CTFramesetterCreateFrame(frameSetter, CFRange.init(location: textPos, length: 0), path, nil)
            let frameRange = CTFrameGetVisibleStringRange(frame)
            let range = NSRange.init(location: frameRange.location, length: frameRange.length)
            let subProgress = attributeStr.attributedSubstring(from: range).length
            progress = progress + Double(subProgress)/total
            print(progress)
            let page = SDZPageModel.init(index: pageIndex, chapter:chapter, range: range)
            page.progress = progress
            pages.append(page)
            pageIndex += 1
            textPos += frameRange.length
        }
        
    }
    // MARK: 解析epub文件
    class func decodeEpubContent(url:URL) throws -> SDZReadModel {
        var unzipPath:String = ""
        do {
            unzipPath = try SDZFileUtilites.unzipEpubFile(form: url)
        }
        catch {
            unzipPath = SDZFileUtilites.cachePath()+"/"+"del"
            var pointer = ObjCBool.init(false)
            let ex = FileManager.default.fileExists(atPath: unzipPath, isDirectory: &pointer)
            if !(ex && pointer.boolValue) {
                try FileManager.default.createDirectory(at: URL(string: unzipPath)!, withIntermediateDirectories: true, attributes: nil)
            }
            try FileManager.default.moveItem(atPath: url.path, toPath: unzipPath)
        }
        guard let unzipPathUrl = URL(string: unzipPath) else {
            throw ReadModelError.urlError("url异常")
        }
        let opfPath = try SDZFileUtilites.opfPath(epubPath: unzipPathUrl)
        guard let opfPathUrl = URL(string: opfPath) else {
            throw ReadModelError.urlError("url异常")
        }
        return try SDZFileUtilites.parseOpfFile(url: opfPathUrl)
    }
    
    // MARK: 解析txt文件
    class func decodeTxtContent(url:URL) throws -> String {
        var content:String = ""
        do {
            content = try String.init(contentsOf: url)
        }
        catch {
            do {
                //windos下编码格式ANSI
                let encode = String.Encoding.init(rawValue: 0x80000632)
                content = try String.init(contentsOf: url, encoding: encode)
            }
            catch {
                throw ReadModelError.encodeError("解码内容失败")
            }
        }
        return content
    }
    
    class private func filePath(key:String?) -> String? {
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
        let filePath = cachePath!+"/\(key ?? "").archiver"
        return filePath
    }
    
    
    class fileprivate func changeAttStrFont(att:NSAttributedString, fontSize:CGFloat) -> NSAttributedString {
        let res = NSMutableAttributedString.init(attributedString: att)
        var range = NSRange.init(location: 0, length: att.length)
        var index = 0
        let standard:CGFloat = 18.0
        while index < att.length {
            let fontAttribute = att.attribute(.font, at: index, effectiveRange: &range) as! UIFont
            let size = fontAttribute.pointSize
            let newSize = (size/(standard)) * fontSize
            let font = UIFont.init(name: fontAttribute.fontName, size: newSize)
            res.addAttribute(.font, value: font ?? UIFont.systemFont(ofSize: fontSize), range: range)
            index = range.upperBound
            range = NSRange.init(location: range.upperBound, length: att.length - range.length)
        }
        return res as NSAttributedString
    }
    
    // 必须将CTParagraphStyle转为NSParagraphStyle 才能进行序列化
    class fileprivate func changeParagraphStyle(att:NSAttributedString) -> NSAttributedString {
        let res = NSMutableAttributedString.init(attributedString: att)
        var range = NSRange.init(location: 0, length: att.length)
        var index = 0
        
        while index < att.length {
            let style = att.attribute(.paragraphStyle, at: index, effectiveRange: &range) as! CTParagraphStyle
            let new = NSParagraphStyle.yy_style(withCTStyle: style)!
            res.addAttribute(.paragraphStyle, value: new, range: range)
            index = range.upperBound
            range = NSRange.init(location: range.upperBound, length: att.length - range.length)
        }
        
        return res as NSAttributedString
    }
}

class SDZFileUtilites {
    // 逃逸闭包不能声明为可选值
    class func saveAsNewAsync(newName:String, url:URL, completion: ((_ success:Bool)->Void)? = nil) {
        let fileDefault = FileManager.default
        let newPath = cachePath()+"/\(newName)"
        DispatchQueue.init(label: "com.file.sdz").async {
            if fileDefault.fileExists(atPath: url.path) {
                do {
                    try fileDefault.moveItem(atPath: url.path, toPath: newPath)
                }
                catch {
                    print("🇨🇳Error : move file failed")
                    do {
                        try fileDefault.removeItem(at: url)
                    }
                    catch {
                        print("🇨🇳Error : delete file failed")
                    }
                    if completion != nil {
                        completion!(false)
                    }
                }
                if completion != nil {
                    completion!(true)
                }
            }
        }
    }
    class func deleteFile(url:URL) {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("🇨🇳删除成功")
            }
        }
        catch {
            assert(false, "delete failed")
        }
    }
    
    class func saveDataAsync(data:Data, fileName:String, completion:@escaping (Bool)->Void) {
        let docURL = URL(string: documentPath())!
        let dataPath = docURL.appendingPathComponent("Reader")
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        let path = URL.init(fileURLWithPath: documentPath()+"/Reader/\(fileName).archiver")
        DispatchQueue.init(label: "com.file.save").async {
            do {
                try data.write(to: path)
                completion(true)
            }
            catch {
                print(error)
                completion(false)
            }
        }
    }
    
    class func cachePath() -> String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
    }
    
    class func documentPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
    }
    
    /*一个能将url中汉字乱码转化的方法
     class func URLDecodedString(str:String) -> String {
     let decodedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(nil, str as CFString, "" as CFString, CFStringConvertNSStringEncodingToEncoding(String.Encoding.utf8.rawValue))
     return decodedString! as String
     }*/
    
    fileprivate class func unzipEpubFile(form url:URL) throws -> String {
        if !FileManager.default.fileExists(atPath: url.path) {
            throw ReadModelError.fileExistsError("文件不存在")
        }
        
        let desPath = cachePath()+"/Epub/"+url.lastPathComponent.replacingOccurrences(of: ".epub", with: "")
        if FileManager.default.fileExists(atPath: desPath) {
            print("🇨🇳 文件已存在")
            return desPath
            
        }
        if !SSZipArchive.unzipFile(atPath: url.path, toDestination: desPath) {
            throw ReadModelError.fileUnzipError("解压错误")
        }
        return desPath
    }
    
    fileprivate class func opfPath(epubPath:URL) throws -> String {
        let containerPath = epubPath.path + "/META-INF/container.xml"
        if FileManager.default.fileExists(atPath: containerPath) {
            let xmlData = FileManager.default.contents(atPath: containerPath)!
            let document = try CXMLDocument.init(data: xmlData, options: 0)
            let opfPath = try document.nodes(forXPath: "//@full-path")
            if opfPath.count != 1 {
                throw ReadModelError.epubError("epub文件异常")
            }
            let path = (opfPath.first! as! CXMLNode).stringValue()
            if path == nil || path!.isEmpty {
                throw ReadModelError.epubError("epub文件异常")
            }
            return epubPath.path + "/" + path!
        } else {
            throw ReadModelError.fileExistsError("epub文件不存在/损坏")
        }
    }
    
    fileprivate class func parseOpfFile(url:URL) throws -> SDZReadModel {
        if url.pathExtension != "opf" {
            throw ReadModelError.epubError("文件格式错误")
        }
        guard let opfData = FileManager.default.contents(atPath: url.path) else {
            throw ReadModelError.fileExistsError("opf文件不存在")
        }
        let document = try CXMLDocument.init(data: opfData, options: 0)
        //opf文件的命名空间 xmlns="http://www.idpf.org/2007/opf" 需要取到某个节点设置命名空间的键为opf 用opf:节点来获取节点
        let items = try document.nodes(forXPath: "//opf:item", namespaceMappings: ["opf":"http://www.idpf.org/2007/opf"])
    
        // todo info
//        let title = readDCValueFromOPF(key: "title", document: document)
//        let creator = readDCValueFromOPF(key: "creator", document: document)
//
//        let cover = readCoverImage(document: document)
        
        var itemDic = [String:String]()
        var ncxFile:String?
        for item in items {
            guard let element = item as? CXMLElement else {
                throw ReadModelError.epubError("opf解析错误1")
            }
            let key = element.attribute(forName: "id")?.stringValue()
            let val = element.attribute(forName: "href")?.stringValue()
            if key == nil || val == nil {
                throw ReadModelError.epubError("opf解析错误2")
            }
            itemDic[key!] = val!
            //获取ncx文件名称 根据ncx获取书的目录
            if element.attribute(forName: "media-type")?.stringValue() == "application/x-dtbncx+xml" {
                ncxFile = element.attribute(forName: "href")?.stringValue()
            }
        }
        
        guard let ncxFile = ncxFile else {
            throw ReadModelError.epubError("opf解析错误3")
        }
        let absolutePath = url.path.replacingOccurrences(of: url.lastPathComponent, with: "")
        let ncxPath = absolutePath+ncxFile
        guard let ncxData = FileManager.default.contents(atPath: ncxPath) else {
            throw ReadModelError.epubError("opf解析错误4")
        }
        let ncxDocument = try CXMLDocument.init(data: ncxData, options: 0)
        var titleDic = [String:String]()
        for item in items {
            guard let element = item as? CXMLElement else {
                throw ReadModelError.epubError("opf解析错误5")
            }
            let href = element.attribute(forName: "href").stringValue() ?? ""
            print("🇨🇳sz", href)
            let xPath = String.init(format: "//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href)
            //根据opf文件的href获取到ncx文件中的中对应的目录名称
            let navPoints = try ncxDocument.nodes(forXPath: xPath, namespaceMappings: ["ncx":"http://www.daisy.org/z3986/2005/ncx/"])
            if !navPoints.isEmpty {
                guard let titleElement = navPoints.first! as? CXMLElement else {
                    throw ReadModelError.epubError("opf解析错误6")
                }
                titleDic[href] = titleElement.stringValue()
            }
        }
        
        let itemRefsArray = try document.nodes(forXPath: "//opf:itemref", namespaceMappings: ["opf":"http://www.idpf.org/2007/opf"])
        var index = 0
        let readModel = SDZReadModel()
        for item in itemRefsArray {
            guard let item = item as? CXMLElement else {
                throw ReadModelError.epubError("opf解析错误7")
            }
            let chapHref = itemDic[item.attribute(forName: "idref").stringValue()]
            let path = absolutePath+(chapHref ?? "")
            let html = String.init(data: try Data.init(contentsOf: URL.init(fileURLWithPath: path)), encoding: .utf8) ?? ""
//            let news = html.removingPercentEncoding ?? ""
//            guard let data = html.data(using: .utf8) else {
//                throw ReadModelError.epubError("opf解析错误8")
//            }
//
//            let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
//            guard let attStr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
//                throw ReadModelError.epubError("opf解析错误9")
//            }
            let opebs = (absolutePath as NSString).substring(to: absolutePath.count - 1)
            guard let newAtt = handleHtml(html: html, oepbsUrl: opebs, chapterUrl: chapHref ?? "") else {
                throw ReadModelError.epubError("opf解析错误9")
            }
            
            let chapterModel = SDZChapterModel.init(index: index, title: (titleDic[chapHref ?? ""] ?? ""), attContent: newAtt)
            chapterModel.attContent = SDZReadUtilites.changeAttStrFont(att: chapterModel.attContent!, fontSize: SDZReadConfig.shared.font.pointSize)
            chapterModel.attContent = SDZReadUtilites.changeParagraphStyle(att: chapterModel.attContent!)
            readModel.chapters.append(chapterModel)
            index += 1
        }
        readModel.type = .epub
        return readModel
    }
    
    fileprivate class func handleHtml(html:String, oepbsUrl:String, chapterUrl:String) -> NSAttributedString? {
        var html = html
        html = html.replacingOccurrences(of: "\r", with: "\n")
        html = html.replacingOccurrences(of: "\n", with: "<p></p>")
        let imagePath = "src=\"" + oepbsUrl
        html = html.replacingOccurrences(of: "src=\"..", with: imagePath)
        html = html.replacingOccurrences(of: "<p></p>", with: "")
        
        let data = html.data(using: .utf8)
        
        let maxImageSize = CGSize.init(width: 200, height: 200)
        
        let dic = [NSTextSizeMultiplierDocumentOption : NSNumber.init(value: 1),
                        DTDefaultLineHeightMultiplier : NSNumber.init(value: 1.5),
                                       DTMaxImageSize : maxImageSize,
                                   DTDefaultLinkColor : "purple",
                          DTDefaultLinkHighlightColor : "red",
                                   DTDefaultTextColor : UIColor.black,
                               DTDefaultTextAlignment : NSNumber.init(value: NSTextAlignment.justified.rawValue),
                              NSBaseURLDocumentOption : NSURL.fileURL(withPath: oepbsUrl+"/"+chapterUrl)
        ] as [String : Any]
        
        let att = NSAttributedString.init(htmlData: data, options: dic, documentAttributes: nil)
        
        return att
    }
    
    fileprivate class func readDCValueFromOPF(key:String, document:CXMLDocument) -> String? {
        let xPath = String.init(format: "//dc:%@[1]", key)
        do{
            let node = try document.nodes(forXPath: xPath, namespaceMappings: ["dc":"http://purl.org/dc/elements/1.1/"]).first as? CXMLNode
            return node?.stringValue()
        }
        catch {
            return nil
        }
    }
    
    fileprivate class func readCoverImage(document:CXMLDocument) -> String? {
        let element = try? document.nodes(forXPath: "//opf:meta[@name='cover']", namespaceMappings: ["opf":"http://www.idpf.org/2007/opf"]).first as? CXMLElement
        let cover = element?.attribute(forName: "content").stringValue()
        return cover
    }
    
}

