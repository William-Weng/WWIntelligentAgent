//
//  MemoryManager.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

import Foundation
import WWSQLite3Manager

// MARK: - Session
public extension WWIntelligentAgent {
    
    /// Agent 記憶管理器（中期記憶：SQLite 持久化）
    class MemoryManager {
        
        private let databaseName: String
        private let tableName: String
        private let rootFolder: URL
        
        private var database: WWSQLite3Manager.Database?
        
        /// 初始化
        /// - Parameters:
        ///   - databaseName: 資料庫名稱
        ///   - tableName: 資料表名稱
        ///   - rootFolder: 資料夾名稱
        public init(databaseName: String = "agent_memory.db", tableName: String = "agent_memories", rootFolder: URL = .documentsDirectory) {
            self.databaseName = databaseName
            self.tableName = tableName
            self.rootFolder = rootFolder
        }
    }
}

// MARK: - Initialization
public extension WWIntelligentAgent.MemoryManager {
    
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
public extension WWIntelligentAgent.MemoryManager {
        
    /// 儲存單筆記憶
    /// - Parameters:
    ///   - sessionId: 會話 ID
    ///   - role: "user" 或 "assistant"
    ///   - content: 訊息內容
    ///   - metadata: 額外資訊（JSON 格式，可選）
    /// - Returns: 是否成功儲存
    @discardableResult
    func saveMemory(sessionId: String, role: WWIntelligentAgent.Role, content: String, metadata: String? = nil) throws -> String {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        let insertItems: [WWSQLite3Manager.InsertItem] = [
            (key: "sessionId", value: sessionId),
            (key: "role", value: "\(role)"),
            (key: "content", value: content),
            (key: "timestamp", value: Date.now),
        ]
        
        return try database.insert(tableName: tableName, itemsArray: [insertItems])
    }
    
    /// 取得某會話的記憶歷史（按時間順序）
    /// - Parameters:
    ///   - sessionId: 會話 ID
    ///   - limit: 最大筆數（nil = 全部）
    /// - Returns: 記憶陣列
    func memoryHistory(sessionId: String, limit: Int? = nil) throws -> [WWIntelligentAgent.Memory]? {
        
        let array = try getMemoryHistory(sessionId: sessionId, limit: limit)
        let memories = array.jsonClass(for: [WWIntelligentAgent.Memory].self)
        
        return memories
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
        
        let memories = result.array.jsonClass(for: [WWIntelligentAgent.Memory].self)
        return memories
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
        let memories = result.array.jsonClass(for: [WWIntelligentAgent.Memory].self)
        
        if let memories { return memories }
        throw WWIntelligentAgent.CustomError.classCastingFailed
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

// MARK: - 小工具
private extension WWIntelligentAgent.MemoryManager {
    
    /// 取得某會話的記憶歷史（按時間順序）
    /// - Parameters:
    ///   - sessionId: 會話 ID
    ///   - limit: 最大筆數（nil = 全部）
    /// - Returns: [[String: Any]]
    func getMemoryHistory(sessionId: String, limit: Int?) throws -> [[String: Any]] {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        
        let whereCondition: WWSQLite3Manager.Where = .init().and("sessionId", .equal, .text(sessionId))
        let orderBy: WWSQLite3Manager.OrderBy = .init().build(orderTypes: [(key: "timestamp", direction: .asc)])
        let limitCondition = limit.map { WWSQLite3Manager.Limit().build(count: $0, offset: 0) }
        
        let result = database.select(tableName: tableName, type: WWIntelligentAgent.Memory.self, where: whereCondition, orderBy: orderBy, limit: limitCondition)
        
        return result.array
    }
}
