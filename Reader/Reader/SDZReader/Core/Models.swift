//
//  Models.swift
//  Reader
//
//  Created by 李方长 on 2021/12/23.
//

import Foundation

enum ReadModelError : Error {
    case urlError(String)
    case extensionError(String)
    case encodeError(String)
    case fileExistsError(String)
    case fileUnzipError(String)
    case epubError(String)
}

enum ReadModelType:String {
    case unknown
    case txt
    case epub
}

class SDZReadModel:NSObject, NSSecureCoding {
    
    var name:String? = nil
    var readHash:String? = nil
    var chapters:[SDZChapterModel] = [SDZChapterModel]()
    var totalLength:Int = 0
    var type:ReadModelType = .unknown
    
    static var supportsSecureCoding: Bool = true
    
    override init() {
        super.init()
    }
    
    init(content:String) {
        self.readHash = Self.createHash(string: content)
        totalLength = content.count
        SDZReadUtilites.separateTxtChapters(chapters: &chapters, content: content, key: self.readHash)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(readHash, forKey: "readHash")
        coder.encode(totalLength, forKey: "totalLength")
        coder.encode(chapters as NSArray, forKey: "chapters")
        coder.encode(type.rawValue, forKey: "type")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        totalLength = coder.decodeInteger(forKey: "totalLength")
        name = coder.decodeObject(forKey: "name") as? String ?? nil
        readHash = coder.decodeObject(forKey: "readHash") as? String ?? nil
        chapters = coder.decodeObject(forKey: "chapters") as? [SDZChapterModel] ?? [SDZChapterModel]()
        type = ReadModelType.init(rawValue: coder.decodeObject(forKey: "type") as? String ?? "unknown") ?? .unknown
    }
    
    class func getReadModel(url:URL) throws -> SDZReadModel? {
        if url.scheme != "file" {
            throw ReadModelError.urlError("url不是文件链接")
        }
        let fileName = url.lastPathComponent
        
        do {
            let readModel = try getReadModel(fileName: fileName)
            return readModel
        }
        catch {
            switch url.pathExtension {
            case "txt" :
                do {
                    let content = try SDZReadUtilites.decodeTxtContent(url: url)
                    let readModel = SDZReadModel.init(content: content)
                    readModel.name = fileName
                    readModel.type = .txt
                    saveArchiverReadModelAsync(readModel: readModel)
                    return readModel
                }
                catch {
                    throw ReadModelError.encodeError("解码内容失败")
                }
            case "epub" :
                do {
                    let readModel = try SDZReadUtilites.decodeEpubContent(url: url)
                    readModel.type = .epub
                    readModel.name = fileName
                    readModel.readHash = Self.createHash(string: url.path)
                    saveArchiverReadModelAsync(readModel: readModel)
                    return readModel
                }
                catch {
                    throw ReadModelError.encodeError("解码内容失败")
                }
            default:
                throw ReadModelError.urlError("文件格式错误")
            }
        }
    }
    
    class func getReadModel(fileName:String) throws -> SDZReadModel {
        let path = URL.init(fileURLWithPath: SDZFileUtilites.documentPath()+"/Reader/\(fileName).archiver")
        if FileManager.default.fileExists(atPath: path.path) {
            let data = FileManager.default.contents(atPath: path.path)!
            let readModel = SDZReadModel.unArchiverReadModel(data: data)
            if readModel != nil {
                return readModel!
            } else {
                throw ReadModelError.encodeError("解码失败")
            }
        } else {
            throw ReadModelError.fileExistsError("本地文件不存在")
        }
    }
    
    class private func saveArchiverReadModelAsync(readModel:SDZReadModel) {
        DispatchQueue.init(label: "com.save.sdz").async {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: readModel, requiringSecureCoding: true)
                
                SDZFileUtilites.saveDataAsync(data: data, fileName: readModel.name!) { success in
                    if success {
                        print("🇨🇳 保存成功")
                        SDZReadConfig.shared.books.append(readModel.name!)
                        UserDefaults.standard.set(SDZReadConfig.shared.books, forKey: "books")
                        NotificationCenter.default.post(name: NSNotification.Name("com.books.update"), object: nil)
                    } else {
                        print("🇨🇳 保存失败")
                    }
                }
            }
            catch {
                print(error)
                assert(false, "🇨🇳archiver Error")
            }
        }
    }
    
    class private func unArchiverReadModel(data:Data) -> SDZReadModel? {
        do {
            let classSet = NSSet.init(objects: NSString.self, NSNumber.self, NSArray.self, SDZReadModel.self, SDZChapterModel.self, NSAttributedString.self)
            let readModel = try NSKeyedUnarchiver.unarchivedObject(ofClasses: classSet as! Set<AnyHashable>, from: data)
            print("🇨🇳解码成功")
            return readModel as? SDZReadModel ?? nil
        }
        catch {
            print(error)
            assert(false, "解码失败")
        }
    }
    
    class func createHash(string:String) -> String {
        let startIndex = string.startIndex
        let min = min(300, string.count)
        let endIndex = string.index(startIndex, offsetBy: min)
        let subContent = string[startIndex..<endIndex]
        
        let csStr = subContent.utf8
        let arraySize = 11113
        var hashCode = 0
        for char in csStr {
            let letterVal = char &- 96
            hashCode = (hashCode << 5 + Int(letterVal))%arraySize
        }
        return "\(hashCode)"
    }
    
}

class SDZChapterModel:NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    var index:Int = 0
    var progress:Double = 0.0
    var title:String = ""
    var content:String = ""
    var attContent:NSAttributedString? = nil
    var attData:Data? = nil
    var type:ReadModelType = .unknown
    var pages:[SDZPageModel] = [SDZPageModel]()
    
    init(index:Int, title:String, content:String) {
        self.index = index
        self.title = title
        self.content = content
        self.type = .txt
    }
    
    init(index:Int, title:String, attContent:NSAttributedString) {
        self.index = index
        self.title = title
        self.attContent = attContent
        self.type = .epub
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(index, forKey: "index")
        coder.encode(title, forKey: "title")
        coder.encode(content, forKey: "content")
        coder.encode(pages as NSArray, forKey: "pages")
        coder.encode(progress, forKey: "progress")
        coder.encode(type.rawValue, forKey: "type")
        // 富文本的归档利用yyText来作处理
        attData = attContent?.yy_archiveToData()
        if attData == nil {
            assert(false, "data!")
        }
        coder.encode(attData, forKey: "attData")
    }
    
    required init?(coder: NSCoder) {
        super.init()
        progress = coder.decodeDouble(forKey: "progress")
        index = coder.decodeInteger(forKey: "index")
        title = coder.decodeObject(forKey: "title") as? String ?? ""
        content = coder.decodeObject(forKey: "content") as? String ?? ""
        pages = coder.decodeObject(forKey: "pages") as? [SDZPageModel] ?? [SDZPageModel]()
        type = ReadModelType.init(rawValue: coder.decodeObject(forKey: "type") as? String ?? "unknown") ?? .unknown
        attData = coder.decodeObject(forKey: "attData") as? Data
        if attData == nil {
            assert(false, "data!")
        }
        attContent = attData == nil ? nil : NSAttributedString.yy_unarchive(from: attData!)

    }

}

class SDZPageModel {
    weak var chapter:SDZChapterModel? = nil
    var index:Int
    //txt
    var content:String {
        get {
            guard let chapter = chapter else {
                return ""
            }
            let string = chapter.content as NSString
            return string.substring(with:range)
        }
    }
    //epub
    var attContent:NSAttributedString {
        get {
            guard let attContent = chapter?.attContent else {
                assert(false, "error")
            }
            let att = attContent.attributedSubstring(from: range)
            return att
        }
    }
    var range:NSRange
    var progress:Double = 0
    init(index:Int, chapter:SDZChapterModel, range:NSRange) {
        self.index = index
        self.range = range
        self.chapter = chapter
    }
}

