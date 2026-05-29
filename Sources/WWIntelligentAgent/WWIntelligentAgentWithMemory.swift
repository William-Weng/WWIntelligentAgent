//
//  WWIntelligentAgentWithMemory.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

import Foundation
import WWIntelligentAgent
import FoundationModels

/// 整合記憶功能的 IntelligentAgent
open class WWIntelligentAgentWithMemory {
    
    private let agent: WWIntelligentAgent
    private let manager: WWIntelligentAgent.MemoryManager
    private let currentSessionId: String
    private let historyPrefixWord: WWIntelligentAgent.HistoryPrefixWord
    
    /// 初始化含記憶功能的Agent
    /// - Parameters:
    ///   - agent: Agent核心
    ///   - sessionId: 對話Id
    ///   - historyPrefixWord: 歷史提示詞前綴字
    public init(agent: WWIntelligentAgent, sessionId: String? = nil, historyPrefixWord: WWIntelligentAgent.HistoryPrefixWord = (title: "以下是最近的對話歷史", null: "無")) throws {
        
        self.agent = agent
        self.currentSessionId = sessionId ?? "session_\(UUID().uuidString)"
        self.historyPrefixWord = historyPrefixWord
        
        try manager = .init()
        try setupMemory()
    }
    
    deinit {
        try? manager.close()
    }
}

// MARK: - 公用工具
public extension WWIntelligentAgentWithMemory {
    
    /// 傳送提示文字給模型，並取得完整回應結果 + 自動保存User記憶
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    /// - Returns: String
    func chat(to prompt: String, limit: Int = 10) async throws -> String {
                
        let historyPrompt = try combineHistoryPrompt(to: prompt, limit: limit)
        let response = try await agent.chat(to: historyPrompt)
        
        try await manager.saveMemory(sessionId: currentSessionId, role: .user, content: prompt)
        
        return response
    }
    
    /// 傳送提示文字給模型，以串流方式取得回應 + 自動保存User記憶
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    /// - Throws: 錯誤
    func streamChat(to prompt: String, limit: Int = 10) async throws -> sending LanguageModelSession.ResponseStream<String> {
        
        let historyPrompt = try combineHistoryPrompt(to: prompt, limit: limit)
        try await manager.saveMemory(sessionId: currentSessionId, role: .user, content: prompt)

        return try await agent.streamChat(to: historyPrompt)
    }
    
    /// 儲存 AI 助理的對話記憶
    /// - Parameter content: AI 助理回應的完整文字內容
    /// - Throws: 當資料庫寫入失敗或工作階段無效時拋出錯誤
    @discardableResult
    func saveAssistantMemory(_ response: String) async throws -> String {
        try await manager.saveMemory(sessionId: currentSessionId, role: .assistant, content: response)
    }
    
    /// 搜尋歷史對話記憶
    /// - Parameter keyword: 要檢索的關鍵字
    /// - Throws: 當檢索失敗或連線中斷時拋出錯誤
    /// - Returns: 符合關鍵字條件的歷史記憶列表
    func searchMemory(keyword: String) throws -> [WWIntelligentAgent.Memory] {
        return try manager.searchMemories(keyword: keyword, sessionId: currentSessionId) ?? []
    }
}

// MARK: - 小工具
private extension WWIntelligentAgentWithMemory {
    
    /// 設定SQLite資料庫
    func setupMemory() throws {
        try manager.connect()
        try manager.createTableIfNotExists()
    }
    
    /// 搜尋並組合聊天記錄 (History + Prompt)
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    /// - Returns: String
    func combineHistoryPrompt(to prompt: String, limit: Int) throws -> String {
        
        let histories = try manager.memoryHistory(sessionId: currentSessionId, limit: 10) ?? []
        let recentContext = histories.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        let historyPrompt = """
            \(historyPrefixWord.title):
            \(recentContext.isEmpty ? "\(historyPrefixWord.null)" : recentContext)
            
            user：\(prompt)
            assistant:
            """
                
        return historyPrompt
    }
}
