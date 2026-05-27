//
//  File.swift
//  WWIntelligentAgent
//
//  Created by iOS on 2026/5/27.
//

import Foundation
import WWIntelligentAgent

/// 整合記憶功能的 IntelligentAgent
public class IntelligentAgentWithMemory {
    
    private let agent: WWIntelligentAgent
    private let memoryManager = WWIntelligentAgent.MemoryManager()
    private let currentSessionId: String
    
    public init(agent: WWIntelligentAgent, sessionId: String? = nil) throws {
        
        self.agent = agent
        self.currentSessionId = sessionId ?? "session_\(UUID().uuidString)"
        
        do {
            try setupMemory()
        } catch {
            throw error
        }
    }
    
    private func setupMemory() throws {
        
        do {
            try memoryManager.connect()
            try memoryManager.createTableIfNotExists()
        } catch {
            throw error
        }
    }
    
    /// 聊天並自動保存記憶 (取得最近 10 筆對話歷史)
    public func chat(_ userMessage: String) async throws -> String? {
        
        do {
            
            let history = try memoryManager.memoryHistory(sessionId: currentSessionId, limit: 10)
            let recentContext = history.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
            
            try memoryManager.saveMemory(sessionId: currentSessionId, role: "user", content: userMessage)
            
            let prompt = """
            以下是最近的對話歷史：
            \(recentContext.isEmpty ? "無" : recentContext)
            
            用戶：\(userMessage)
            Assistant:
            """
            
            print(prompt)
            
            let response = try await agent.chat(to: prompt)
            try memoryManager.saveMemory(sessionId: currentSessionId, role: "assistant", content: response ?? "")
            
            return response
            
        } catch {
            throw error
        }
    }
    
    /// 搜尋記憶
    func searchMemory(keyword: String) throws -> [WWIntelligentAgent.Memory] {
        
        do {
            return try memoryManager.searchMemories(keyword: keyword, sessionId: currentSessionId)
        } catch {
            throw error
        }
    }
    
    deinit {
        try? memoryManager.close()
    }
}
