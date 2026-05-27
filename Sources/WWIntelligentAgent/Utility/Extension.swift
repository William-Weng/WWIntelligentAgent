//
//  Extension.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

import Foundation
import FoundationModels

// MARK: - JSONSerialization
extension JSONSerialization {
    
    /// [JSONObject => JSON Data](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-jsonserialization-印出美美縮排的-json-308c93b51643)
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameters:
    ///   - object: Any
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    static func _data(with object: Any, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options)
        else {
            return nil
        }
        
        return data
    }
}

// MARK: - Sequence
extension Sequence {
        
    /// Array => JSON Data
    /// - ["name","William"] => {"name","William"} => 5b226e616d65222c2257696c6c69616d225d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = .init()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
    
    /// Array => JSON Object
    /// - Parameters:
    ///   - writingOptions: JSONSerialization.WritingOptions
    ///   - readingOptions: JSONSerialization.ReadingOptions
    /// - Returns: Any?
    func _jsonObject(writingOptions: JSONSerialization.WritingOptions = .init(), readingOptions: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        return self._jsonData(options: writingOptions)?._jsonObject(options: readingOptions)
    }
    
    /// Array => JSON Data => [T]
    /// - Parameter type: 要轉換成的Array類型
    /// - Returns: [T]?
    func _jsonClass<T: Decodable>(for type: [T].Type) -> [T]? {
        
        guard let data = self._jsonData(),
              let array = data._class(type: [T].self)
        else {
            return nil
        }
        
        return array
    }
}

// MARK: - Data
extension Data {
    
    /// [Data => JSON](https://blog.zhgchg.li/現實使用-codable-上遇到的-decode-問題場景總匯-下-cb00b1977537)
    /// - 7b2268747470223a2022626f6479227d => {"http": "body"}
    /// - Returns: Any?
    func _jsonObject(options: JSONSerialization.ReadingOptions = .allowFragments) -> Any? {
        let json = try? JSONSerialization.jsonObject(with: self, options: options)
        return json
    }
    
    /// Data => Class
    /// - Parameter type: 要轉型的Type => 符合Decodable
    /// - Returns: T => 泛型
    func _class<T: Decodable>(type: T.Type, dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZ") -> T? {
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "UTC")

        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try? decoder.decode(type.self, from: self)
    }
    
    /// Data => 字串
    /// - Parameter encoding: 字元編碼
    /// - Returns: String?
    func _string(using encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
}

// MARK: - String
extension String {
    
    /// 驗證目前字串是否可作為語言模型使用的提示文字
    ///
    /// 此方法會先移除前後空白與換行字元，再進行檢查
    ///
    /// - Throws: 當修剪後的文字為空時，拋出 `WWIntelligentAgent.CustomError.promptIsEmpty`
    /// - Returns: 可安全送入模型的提示文字
    func validatedPrompt() throws -> String {
        
        let prompt = trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !prompt.isEmpty else { throw WWIntelligentAgent.CustomError.promptIsEmpty }
        return prompt
    }
}

// MARK: - LanguageModelSession
extension LanguageModelSession {
    
    /// 送出經過驗證的提示文字，並回傳模型產生的結果
    ///
    /// 此方法會先驗證輸入文字，再呼叫 `respond(to:options:)`
    ///
    /// - Parameters:
    ///   - prompt: 原始輸入文字
    ///   - optionType: 產生內容時使用的選項類型
    /// - Throws: 可能拋出提示文字驗證錯誤，或模型回應過程中的錯誤
    /// - Returns: 包含模型回應文字的結果物件
    func respondSafely(to prompt: String, optionType: WWIntelligentAgent.OptionType) async throws -> LanguageModelSession.Response<String> {
        try await respond(to: prompt.validatedPrompt(), options: optionType.value())
    }
    
    /// 送出經過驗證的提示文字，並以串流方式回傳模型結果
    ///
    /// 此方法會先驗證輸入文字，再呼叫 `streamResponse(to:options:)`
    ///
    /// - Parameters:
    ///   - prompt: 原始輸入文字
    ///   - optionType: 產生內容時使用的選項類型
    /// - Throws: 可能拋出提示文字驗證錯誤，或模型回應過程中的錯誤
    /// - Returns: 逐步產生內容的回應串流
    func streamRespondSafely(to prompt: String, optionType: WWIntelligentAgent.OptionType) throws -> sending LanguageModelSession.ResponseStream<String> {
        try streamResponse(to: prompt.validatedPrompt(), options: optionType.value())
    }
}

// MARK: - Dictionary (function)
extension Dictionary {
    
    /// Dictionary => JSON Data
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameter options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
    
    /// Dictionary => JSON Object
    /// - Parameters:
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Any?
    func _jsonObject(options: JSONSerialization.WritingOptions = .prettyPrinted) -> Any? {
        
        guard let data = self._jsonData(options: options),
              let jsonObject = data._jsonObject()
        else {
            return nil
        }
        
        return jsonObject
    }
    
    /// Dictionary => JSON String
    /// - Parameters:
    ///   - options: JSONSerialization.WritingOptions
    ///   - encoding: String.Encoding
    /// - Returns: String?
    func _jsonString(options: JSONSerialization.WritingOptions = .prettyPrinted, using encoding: String.Encoding = .utf8) -> String? {
        
        guard let data = self._jsonData(options: options),
              let jsonString = data._string(using: encoding)
        else {
            return nil
        }
        
        return jsonString
    }
    
    /// Dictionary => JSON Data => T
    /// - Parameter type: 要轉換成的Dictionary類型
    /// - Returns: [T]?
    func _jsonClass<T: Decodable>(for type: T.Type) -> T? {
        let dictionary = self._jsonData()?._class(type: type.self)
        return dictionary
    }
    
    /// Dictionary => Key1=Value1&Key2=Value2
    /// - Parameter separator: 分隔號
    /// - Returns: String
    func _queryString(separator: String = "&") -> String {
        
        var string = ""
        var array: [String] = []
        
        for (key, value) in self { array.append("\(key)=\(value)") }
        string = array.joined(separator: separator)
        
        return string
    }
}
