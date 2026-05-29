//
//  MemoryManager.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

import Foundation
import WWSQLite3Manager
import NaturalLanguage

// MARK: - MemoryManager
extension WWIntelligentAgent {
    
    /// Agent 記憶管理器（中期記憶：SQLite 持久化）
    class MemoryManager {
        
        private let databaseName: String
        private let tableName: String
        private let rootFolder: URL
        private let embedding: EmbeddingManager
        
        private var database: WWSQLite3Manager.Database?
        
        /// 初始化
        /// - Parameters:
        ///   - databaseName: 資料庫名稱
        ///   - tableName: 資料表名稱
        ///   - rootFolder: 資料夾名稱
        ///   - language: 要處理的語系（NLLanguage），例如 .chinese, .english
        public init(databaseName: String, tableName: String, rootFolder: URL, language: NLLanguage) throws {
            
            self.databaseName = databaseName
            self.tableName = tableName
            self.rootFolder = rootFolder
            self.embedding = try EmbeddingManager(for: language)
        }
    }
}

// MARK: - Initialization
extension WWIntelligentAgent.MemoryManager {
    
    /// 初始化並連接資料庫
    /// - Returns: 是否成功連接
    func connect() throws {
        database = try WWSQLite3Manager.shared.connect(for: rootFolder, filename: databaseName)
    }
    
    /// 建立記憶表格（首次使用時呼叫）
    func createTableIfNotExists() throws {
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        try database.create(tableName: tableName, type: WWIntelligentAgent.Memory.self, ifNotExists: true)
    }
}

// MARK: - CRUD Operations
extension WWIntelligentAgent.MemoryManager {
        
    /// 儲存單筆記憶
    /// - Parameters:
    ///   - sessionId: 會話 ID
    ///   - role: "user" 或 "assistant"
    ///   - content: 訊息內容
    ///   - metadata: 額外資訊（JSON 格式，可選）
    /// - Returns: 是否成功儲存
    @discardableResult
    func saveMemory(sessionId: String, role: WWIntelligentAgent.Role, content: String, metadata: String? = nil) async throws -> String {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        
        let embedding = await embedding.embed(content)
        let embeddingData = embedding.data()
        let metadataValue: WWSQLite3Manager.InsertValue = if let metadata { .string(metadata) } else { .null }
        
        let insertItems: [WWSQLite3Manager.InsertItem] = [
            (key: "sessionId", value: .string(sessionId)),
            (key: "role", value: .string("\(role)")),
            (key: "content", value: .string(content)),
            (key: "timestamp", value: .date(Date.now)),
            (key: "metadata", value: metadataValue),
            (key: "embedding", value: .data(embeddingData)),
        ]
        
        return try database.insert(tableName: tableName, itemsArray: [insertItems])
    }
    
    /// 取得某會話的記憶歷史（按時間順序）
    /// - Parameters:
    ///   - sessionId: 會話 ID（nil = 全會話ID）
    ///   - limit: 最大筆數（nil = 全部）
    /// - Returns: 記憶陣列
    func memoryHistory(sessionId: String?, limit: Int? = nil) throws -> [WWIntelligentAgent.Memory] {
        
        let result = try getMemoryHistory(sessionId: sessionId, limit: limit)
        return try parseSelectMemoryHistory(result: result)
    }
    
    /// 取得最近 N 筆記憶（所有會話）
    /// - Parameters:
    ///   - limit: 最大筆數（預設 50）
    /// - Returns: 記憶陣列
    func recentMemories(limit: Int = 50) throws -> [WWIntelligentAgent.Memory]? {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        let orderBy: WWSQLite3Manager.OrderBy = .init().build(orderTypes: [(key: "timestamp", direction: .asc)])
        let limitCondition = WWSQLite3Manager.Limit().build(count: limit, offset: 0)
        let result = database.select(tableName: tableName, type: WWIntelligentAgent.Memory.self, orderBy: orderBy, limit: limitCondition)
        
        return try parseSelectMemoryHistory(result: result)
    }
    
    /// 搜尋包含關鍵字的名記憶（使用 LIKE）
    /// - Parameters:
    ///   - keyword: 搜尋關鍵字
    ///   - sessionId: 可選的會話 ID 過濾
    ///   - limit: 最大筆數
    /// - Returns: 符合的記憶陣列
    func searchMemories(keyword: String, sessionId: String? = nil, limit: Int = 20) throws -> [WWIntelligentAgent.Memory] {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        var whereCondition: WWSQLite3Manager.Where = .init().like(key: "content", pattern: "%\(keyword)%")
        
        if let sessionId = sessionId { whereCondition = whereCondition.and("sessionId", .equal, .text(sessionId)) }
        
        let orderBy: WWSQLite3Manager.OrderBy = .init().build(orderTypes: [(key: "timestamp", direction: .desc)])
        let limitCondition = WWSQLite3Manager.Limit().build(count: limit, offset: 0)
        
        let result = database.select(tableName: tableName, type: WWIntelligentAgent.Memory.self, where: whereCondition, orderBy: orderBy, limit: limitCondition)
        
        return try parseSelectMemoryHistory(result: result)
    }
    
    /// 清除某會話的所有記憶
    /// - Parameter sessionId: 會話 ID
    /// - Returns: 是否成功清除
    func clearSessionMemory(sessionId: String) throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        let whereCondition: WWSQLite3Manager.Where = .init().and("sessionId", .equal, .text(sessionId))
        try database.delete(tableName: tableName, where: whereCondition)
    }
    
    /// 刪除過期的記憶（例如：超過 30 天）
    /// - Parameter olderThanDays: 天數（預設 30）
    /// - Returns: 是否成功刪除
    func deleteExpiredMemories(olderThanDays: Int = 30) throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        guard let currentOffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) else { return }
        
        let whereCondition: WWSQLite3Manager.Where = .init().and("timestamp", .lessThan, .text("\(currentOffDate)"))
        try database.delete(tableName: tableName, where: whereCondition)
    }
    
    /// 關閉資料庫連線
    func close() throws {
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        try database.close()
    }
}

// MARK: - 語意搜尋（Embedding）
extension WWIntelligentAgent.MemoryManager {
    
    /// 使用 Embedding 搜尋語意相似的記憶
    /// 
    /// 將查詢文字轉成向量，然後在記憶中找餘弦相似度最高的前 K 筆。
    /// 
    /// - Parameters:
    ///   - query: 查詢文字（例如使用者的問題）
    ///   - sessionId: 會話 ID（過濾特定 session）
    ///   - topK: 傳回前 K 筆最相似的記憶
    ///   - limit: 搜尋記憶的最大筆數
    /// - Returns: 最相似的記憶陣列
    func findSimilarMemories(query: String, sessionId: String? = nil, topK: Int = 5, limit: Int = 1000) async throws -> [WWIntelligentAgent.Memory]? {
        
        let queryVector = await embedding.embed(query)
        guard !queryVector.isEmpty else { return nil }
        
        let memories: [WWIntelligentAgent.Memory]
        
        if let sessionId = sessionId {
            memories = try memoryHistory(sessionId: sessionId, limit: limit) ?? []
        } else {
            memories = try memoryHistory(sessionId: nil, limit: limit) ?? []
        }
        
        let memoriesWithEmbedding = memories.filter { $0.embedding != nil && !$0.embedding!.isEmpty }
        guard !memoriesWithEmbedding.isEmpty else { return nil }
        
        var scoredMemories: [(WWIntelligentAgent.Memory, Float)] = []
        
        for memory in memoriesWithEmbedding {
            
            guard let memoryEmbedding = memory.embedding else { continue }
            
            let similarity = await embedding.cosineSimilarity(queryVector, memoryEmbedding)
            scoredMemories.append((memory, similarity))
        }
                
        let sorted = scoredMemories.sorted { $0.1 > $1.1 }
        let topMemories = sorted.prefix(topK).map { $0.0 }
                
        return Array(topMemories)
    }
}

// MARK: - 小工具
private extension WWIntelligentAgent.MemoryManager {
    
    /// 取得某會話的記憶歷史（按時間順序）
    /// - Parameters:
    ///   - sessionId: 會話 ID（nil = 全會話ID）
    ///   - limit: 最大筆數（nil = 全部）
    /// - Returns: WWSQLite3Manager.SelectResult
    func getMemoryHistory(sessionId: String?, limit: Int?) throws -> WWSQLite3Manager.SelectResult {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        
        var whereCondition: WWSQLite3Manager.Where? = nil
        if let sessionId { whereCondition = .init().and("sessionId", .equal, .text(sessionId)) }
        
        let orderBy: WWSQLite3Manager.OrderBy = .init().build(orderTypes: [(key: "timestamp", direction: .asc)])
        let limitCondition = limit.map { WWSQLite3Manager.Limit().build(count: $0, offset: 0) }
        
        let result = database.select(tableName: tableName, type: WWIntelligentAgent.Memory.self, where: whereCondition, orderBy: orderBy, limit: limitCondition)
        
        return result
    }
    
    /// 從 SQLite SELECT 結果解析記憶歷史（[Memory]）
    ///
    /// 將 `WWSQLite3Manager.SelectResult` 中的每一列（row）轉換成 `WWIntelligentAgent.Memory`
    ///
    /// 欄位對應：
    /// - sessionId: String
    /// - role: String（例如 "user" / "assistant"）
    /// - content: String
    /// - timestamp: String（ISO 8601）→ 轉成 Date
    /// - metadata: String?（可選）
    /// - embedding: Data?（BLOB，Float 向量）→ 轉成 [Float]?
    ///
    /// - Parameter result: SQLite SELECT 查詢結果
    /// - Returns: 成功解析的記憶陣列，無效列會被過濾掉
    func parseSelectMemoryHistory(result: WWSQLite3Manager.SelectResult) throws -> [WWIntelligentAgent.Memory] {
        
        let memories: [WWIntelligentAgent.Memory] = try result.array.compactMap { row in
            
            guard let sessionId = row["sessionId"] as? String,
                  let role = row["role"] as? String,
                  let content = row["content"] as? String,
                  let timestamp = (row["timestamp"] as? String)?.date()
            else {
                throw WWIntelligentAgent.CustomError.classCastingFailed
            }
            
            let metadata = row["metadata"] as? String
            let embedding = row["embedding"] as? Data
            
            return .init(sessionId: sessionId, role: role, content: content, timestamp: timestamp, metadata: metadata, embedding: embedding?.floatVector())
        }
        
        return memories
    }
}

