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
    
    /// 初始化
    /// - Parameters:
    ///   - agent: Agent核心
    ///   - sessionId: 對話Id
    ///   - historyPrefixWord: 歷史提示詞前綴字
    public init(agent: WWIntelligentAgent, sessionId: String? = nil, historyPrefixWord: WWIntelligentAgent.HistoryPrefixWord = (title: "以下是最近的對話歷史", null: "無", user: "使用者", assistant: "Assistant")) throws {
        
        self.agent = agent
        self.currentSessionId = sessionId ?? "session_\(UUID().uuidString)"
        self.manager = .init()
        self.historyPrefixWord = historyPrefixWord

        try setupMemory()
    }
    
    deinit {
        try? manager.close()
    }
}

// MARK: - 公用工具
public extension WWIntelligentAgentWithMemory {
    
    /// 傳送提示文字給模型，並取得完整回應結果，自動保存記憶
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    /// - Returns: String
    func chat(to prompt: String, limit: Int = 10) async throws -> String {
        
        let historyPrompt = try combineHistoryPrompt(to: prompt, limit: limit)
        let response = try await agent.chat(to: historyPrompt)
        
        try manager.saveMemory(sessionId: currentSessionId, role: .assistant, content: response)
        
        return response
    }
    
    /// 傳送提示文字給模型，以串流方式取得回應，並自動保存完整記憶
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    ///   - onUpdate: 每個 chunk 回傳給 UI 的 callback（可以即時更新）
    /// - Throws: 錯誤
    func streamChat(to prompt: String, limit: Int = 10, onUpdate: @escaping (LanguageModelSession.ResponseStream<String>.Snapshot) -> Void) async throws {
        
        let historyPrompt = try combineHistoryPrompt(to: prompt, limit: limit)
        var response: LanguageModelSession.ResponseStream<String>.Snapshot!
        
        for try await chunk in try await agent.streamChat(to: historyPrompt) {
            response = chunk
            onUpdate(response)
        }
        
        try manager.saveMemory(sessionId: currentSessionId, role: .assistant, content: response.content)
    }
    
    /// 搜尋記憶
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
        
        let history = try manager.memoryHistory(sessionId: currentSessionId, limit: 10) ?? []
        let recentContext = history.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        
        try manager.saveMemory(sessionId: currentSessionId, role: .user, content: prompt)
        
        let historyPrompt = """
            \(historyPrefixWord.title):
            \(recentContext.isEmpty ? "\(historyPrefixWord.null)" : recentContext)
            
            \(historyPrefixWord.user)：\(prompt)
            \(historyPrefixWord.assistant):
            """
        
        return historyPrompt
    }
}
