//
//  Extension.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

// MARK: - JSONSerialization
@available(iOS 26.0, *)
extension JSONSerialization {
    
    /// [JSONObject => JSON Data](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-jsonserialization-印出美美縮排的-json-308c93b51643)
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameters:
    ///   - object: Any
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    static func data(with object: Any, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options)
        else {
            return nil
        }
        
        return data
    }
}

// MARK: - Array
@available(iOS 26.0, *)
extension Array where Element == Float {
    
    /// 將 Float 陣列轉成 Data（二進位）
    ///
    /// 用途：
    /// - 儲存 embedding 向量到 SQLite / 檔案
    /// - 網路傳輸 embedding 向量
    /// - 與 C / Core ML / Accelerate 等 API 串接（需要原始二進位）
    ///
    /// - Returns: 包含原始二進位資料的 `Data`
    ///
    /// 實作細節：
    /// - `self.count`: Float 元素個數（例如 768）
    /// - `MemoryLayout<Element>.size`: 每個 Float 的 bytes 大小（4 bytes）
    /// - 總 bytes = count × 4
    /// - `Data(bytes:count:)` 會複製陣列的連續記憶體
    func data() -> Data {
        Data(bytes: self, count: count * MemoryLayout<Element>.size)
    }
}

// MARK: - Data
extension Data {
    
    /// 將 SQLite 的 BLOB 二進位資料還原為 [Float] 向量
    /// - Returns: 成功還原的 `[Float]`，若資料為空則回傳 `[]`
    func floatVector() -> [Float] {
        
        let floatSize = MemoryLayout<Float>.size
        let count = self.count / floatSize
        
        guard count > 0 else { return [] }
        
        return self.withUnsafeBytes { bytes in
            let floatBuffer = bytes.bindMemory(to: Float.self)
            return [Float](floatBuffer)
        }
    }
}

// MARK: - String
@available(iOS 26.0, *)
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
    
    /// 將"2020-07-08 16:36:31 +0800" => Date()
    /// - Parameters:
    ///   - dateFormat: Constant.DateFormat
    ///   - timeZone: TimeZone
    /// - Returns: Date?
    func date(dateFormat: String = "yyyy-MM-dd HH:mm:ss ZZZ", timeZone: TimeZone = .current) -> Date? {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = "\(dateFormat)"
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.date(from: self)
    }
}

// MARK: - LanguageModelSession
@available(iOS 26.0, *)
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

#endif
