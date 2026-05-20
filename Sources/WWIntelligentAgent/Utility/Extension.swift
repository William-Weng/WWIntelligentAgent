//
//  Extension.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

import FoundationModels

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
