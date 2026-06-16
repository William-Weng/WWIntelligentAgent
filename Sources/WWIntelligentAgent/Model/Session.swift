//
//  Model.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

#if canImport(FoundationModels)
import FoundationModels

// MARK: - Session
@available(iOS 26.0, *)
extension WWIntelligentAgent {
    
    /// 負責封裝 `LanguageModelSession` 的 actor
    ///
    /// 此型別用來隔離語言模型工作階段的存取，避免多個並行工作同時操作，同一個 `LanguageModelSession`，以符合 Swift 6 的安全並行模型。
    actor Session {
        
        private let session: LanguageModelSession
        
        /// 初始化
        /// - Parameter session: 目前建立的語言模型工作階段
        init(session: LanguageModelSession) {
            self.session = session
        }
    }
}

// MARK: - 公開工具
@available(iOS 26.0, *)
extension WWIntelligentAgent.Session {
    
    /// 傳送提示文字給模型，並取得完整回應結果
    ///
    /// 此方法會先檢查目前工作階段是否可用，再驗證提示文字內容，最後呼叫模型產生完整文字回應
    ///
    /// - Parameter prompt: 要送給模型的提示文字
    /// - Throws: 當工作階段不存在、模型不可用，或提示文字為空時拋出錯誤
    /// - Returns: 包含模型完整回應內容的結果物件
    func chat(to prompt: String, optionType: WWIntelligentAgent.OptionType) async throws -> String {
        try await session.respondSafely(to: prompt, optionType: optionType).content
    }
    
    /// 傳送提示文字給模型，並以串流方式取得回應結果
    ///
    /// 此方法會先檢查提示文字是否有效，再確認目前工作階段是否可用，最後回傳可逐步讀取內容的回應串流
    ///
    /// - Parameter prompt: 要送給模型的提示文字
    /// - Throws: 當工作階段不存在、模型不可用，或提示文字為空時拋出錯誤
    /// - Returns: 可逐步接收模型回應內容的串流物件
    func streamChat(to prompt: String, optionType: WWIntelligentAgent.OptionType) throws -> sending LanguageModelSession.ResponseStream<String> {
        try session.streamRespondSafely(to: prompt, optionType: optionType)
    }
}

#endif
