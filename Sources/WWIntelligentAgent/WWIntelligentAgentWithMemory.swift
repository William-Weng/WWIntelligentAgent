//
//  WWIntelligentAgentWithMemory.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

import Foundation
import FoundationModels
import NaturalLanguage

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
    ///   - language: 要處理的語系（NLLanguage），例如 .chinese, .english
    public init(agent: WWIntelligentAgent, sessionId: String? = nil, historyPrefixWord: WWIntelligentAgent.HistoryPrefixWord = .init(), language: NLLanguage = .english) throws {
        
        let databaseName = "agent_memory.db"
        let tableName = "agent_memories"
        let rootFolder: URL = .documentsDirectory
        
        self.agent = agent
        self.currentSessionId = sessionId ?? "session_\(UUID().uuidString)"
        self.historyPrefixWord = historyPrefixWord
        
        try manager = .init(databaseName: databaseName, tableName: tableName, rootFolder: rootFolder, language: language)
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
    ///   - useSemanticSearch: 是否啟用語意搜尋（Embedding），預設為 false
    ///   - similarLimit: 語意搜尋取前 K 筆相似記憶，預設為 5
    /// - Returns: String
    func chat(to prompt: String, limit: Int = 10, useSemanticSearch: Bool = false, similarLimit: Int = 5) async throws -> String {
        
        let historyPrompt = try await combineHistoryPrompt(to: prompt, limit: limit, useSemanticSearch: useSemanticSearch, similarLimit: similarLimit)
        let response = try await agent.chat(to: historyPrompt)
        
        try await manager.saveMemory(sessionId: currentSessionId, role: .user, content: prompt)
        
        return response
    }
    
    /// 傳送提示文字給模型，以串流方式取得回應 + 自動保存User記憶
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字
    ///   - limit: 取得最近對話歷史筆數
    ///   - useSemanticSearch: 是否啟用語意搜尋（Embedding），預設為 false
    ///   - similarLimit: 語意搜尋取前 K 筆相似記憶，預設為 5
    /// - Throws: 錯誤
    func streamChat(to prompt: String, limit: Int = 10, useSemanticSearch: Bool = false, similarLimit: Int = 5) async throws -> sending LanguageModelSession.ResponseStream<String> {
        
        let historyPrompt = try await combineHistoryPrompt(to: prompt, limit: limit, useSemanticSearch: useSemanticSearch, similarLimit: similarLimit)
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
    ///
    /// 將最近的對話歷史與使用者當前的提示（prompt）組合，形成完整提示送給模型。
    /// 支援選擇性語意搜尋（RAG），可根據提示找最相關的記憶。
    ///
    /// - Parameters:
    ///   - prompt: 要送給模型的提示文字（使用者當前的問題）
    ///   - limit: 取得最近對話歷史筆數
    ///   - useSemanticSearch: 是否啟用語意搜尋（Embedding），預設為 false
    ///   - similarLimit: 語意搜尋取前 K 筆相似記憶，預設為 5
    /// - Returns: 組合後的完整提示字串
    func combineHistoryPrompt(to prompt: String, limit: Int, useSemanticSearch: Bool, similarLimit: Int) async throws -> String {
        
        let histories = try manager.memoryHistory(sessionId: currentSessionId, limit: limit) ?? []
        let recentContext = histories.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        let similarContext = try await searchSimilarContext(to: prompt, useSemanticSearch: useSemanticSearch, similarLimit: similarLimit)
        
        var parts: [String] = []
        
        if let similar = similarContext {
            parts.append("""
                \(historyPrefixWord.relevantMemories):
                \(similar)
                
                """)
        }
        
        // 加入歷史對話
        parts.append("""
            \(historyPrefixWord.title):
            \(recentContext.isEmpty ? "\(historyPrefixWord.null)" : recentContext)
            """)
        
        // 加入使用者當前提示
        parts.append("user: \(prompt)")
        parts.append("assistant:")
        
        return parts.joined(separator: "\\n")
    }
    
    /// 格式化相似記憶（可選語意搜尋）
    func searchSimilarContext(to prompt: String, useSemanticSearch: Bool, similarLimit: Int) async throws -> String? {
        
        let similarMemories = try await searchSimilarMemories(to: prompt, useSemanticSearch: useSemanticSearch, similarLimit: similarLimit)
        
        guard let memories = similarMemories,
              memories.isEmpty
        else {
            return nil
        }
        
        let similarContext = memories.map { "\($0.role): \($0.content)" }.joined(separator: "\\n")
        return similarContext
    }
    
    /// 搜尋相似記憶（可選語意搜尋）
    ///
    /// - Parameters:
    ///   - prompt: 查詢文字（使用者的問題）
    ///   - useSemanticSearch: 是否啟用語意搜尋
    ///   - similarLimit: 取前 K 筆相似記憶
    /// - Returns: 最相似的記憶陣列，若未啟用語意搜尋則回傳 `nil`
    func searchSimilarMemories(to prompt: String, useSemanticSearch: Bool, similarLimit: Int) async throws -> [WWIntelligentAgent.Memory]? {
        guard useSemanticSearch else { return nil }
        return try await manager.findSimilarMemories(query: prompt, topK: similarLimit)
    }
}
