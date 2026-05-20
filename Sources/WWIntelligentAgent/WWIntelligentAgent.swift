//
//  WWIntelligentAgent.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

import FoundationModels

/// 一個簡單的智慧代理包裝器，用來管理 `LanguageModelSession` 的建立與對話流程
///
/// 此類別負責保存模型、系統指令與工具設定，並提供一般回應與串流回應兩種呼叫方式
@MainActor
open class WWIntelligentAgent {
    
    public let model: SystemLanguageModel           // 目前使用的系統語言模型

    private var session: LanguageModelSession?      // 目前建立的語言模型工作階段
    private var instructions: String?               // 套用在工作階段上的系統指令
    private var tools: [any Tool] = []              // 套用在工作階段上的工具列表
    
    /// 建立一個智慧代理實例
    ///
    /// 初始化後會依照目前的模型、工具與指令狀態建立一個新的 `LanguageModelSession`
    ///
    /// - Parameter model: 要使用的系統語言模型，預設為 `.default`
    public init(model: SystemLanguageModel = .default) {
        self.model = model
        rebuildSession()
    }
}

// MARK: - 公開函式
public extension WWIntelligentAgent {
    
    /// 設定系統指令與工具，並重新建立工作階段
    ///
    /// 當指令或工具內容變更時，會重新產生新的 `LanguageModelSession`，讓後續請求使用最新的設定
    ///
    /// - Parameters:
    ///   - instructions: 要提供給模型的系統指令，預設為 `nil`
    ///   - tools: 要提供給模型使用的工具列表，預設為空陣列
    func configure(with instructions: String? = nil, tools: [any Tool] = []) {
        self.instructions = instructions
        self.tools = tools
        rebuildSession()
    }
    
    /// 傳送提示文字給模型，並取得完整回應結果
    ///
    /// 此方法會先檢查目前工作階段是否可用，再驗證提示文字內容，最後呼叫模型產生完整文字回應
    ///
    /// - Parameter prompt: 要送給模型的提示文字
    /// - Throws: 當工作階段不存在、模型不可用，或提示文字為空時拋出錯誤
    /// - Returns: 包含模型完整回應內容的結果物件
    func chat(to prompt: String) async throws -> LanguageModelSession.Response<String> {
        let session = try findSession()
        return try await session.respondSafely(to: prompt)
    }
    
    /// 傳送提示文字給模型，並以串流方式取得回應結果
    ///
    /// 此方法會先檢查提示文字是否有效，再確認目前工作階段是否可用，最後回傳可逐步讀取內容的回應串流
    ///
    /// - Parameter prompt: 要送給模型的提示文字
    /// - Throws: 當工作階段不存在、模型不可用，或提示文字為空時拋出錯誤
    /// - Returns: 可逐步接收模型回應內容的串流物件
    func streamChat(to prompt: String) async throws -> LanguageModelSession.ResponseStream<String> {
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CustomError.promptIsEmpty }
        
        let session = try findSession()
        return try session.streamRespondSafely(to: prompt)
    }
}

// MARK: - 小工具
private extension WWIntelligentAgent {
    
    /// 依照目前的模型、工具與系統指令重新建立工作階段
    ///
    /// 當設定內容變更時，應重新呼叫此方法以確保 session 使用的是最新狀態
    func rebuildSession() {
        session = LanguageModelSession(model: model, tools: tools, instructions: instructions)
    }
    
    /// 取得目前可用的工作階段
    ///
    /// 此方法會先確認 session 是否已建立，再檢查目前模型是否可在裝置上使用
    ///
    /// - Throws: 當工作階段不存在或模型不可用時拋出錯誤
    /// - Returns: 一個可使用的 `LanguageModelSession`
    func findSession() throws -> LanguageModelSession {
        
        guard let session else { throw CustomError.sessionNotFound }
        guard model.isAvailable else { throw CustomError.modelUnavailable }
        
        return session
    }
}
