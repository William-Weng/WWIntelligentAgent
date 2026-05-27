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
        
        private var database: WWSQLite3Manager.Database?
        
        public init(databaseName: String = "agent_memory.db", tableName: String = "agent_memories") {
            self.databaseName = databaseName
            self.tableName = tableName
        }
    }
}

// MARK: - Initialization
public extension WWIntelligentAgent.MemoryManager {
    
    /// 初始化並連接資料庫
    /// - Returns: 是否成功連接
    func connect() throws {
        
        do {
            database = try WWSQLite3Manager.shared.connect(for: .documentsDirectory, filename: databaseName)
        } catch {
            throw error
        }
    }
    
    /// 建立記憶表格（首次使用時呼叫）
    func createTableIfNotExists() throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        
        do {
            try database.create(tableName: tableName, type: WWIntelligentAgent.Memory.self, ifNotExists: true)
        } catch {
            throw error
        }
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
    func saveMemory(sessionId: String, role: String, content: String, metadata: String? = nil) throws -> String {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        let insertItems: [WWSQLite3Manager.InsertItem] = [
            (key: "sessionId", value: sessionId),
            (key: "role", value: role),
            (key: "content", value: content),
            (key: "timestamp", value: Date()),
        ]
        
        do {
            let sql = try database.insert(tableName: tableName, itemsArray: [insertItems])
            return sql
        } catch {
            throw error
        }
    }
    
    /// 取得某會話的記憶歷史（按時間順序）
    /// - Parameters:
    ///   - sessionId: 會話 ID
    ///   - limit: 最大筆數（nil = 全部）
    /// - Returns: 記憶陣列
    func memoryHistory(sessionId: String, limit: Int? = nil) throws -> [WWIntelligentAgent.Memory]? {
        
        do {
            let array = try getMemoryHistory(sessionId: sessionId, limit: limit)
            let memories = array._jsonClass(for: [WWIntelligentAgent.Memory].self)
            return memories
        } catch {
            throw error
        }
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
        
        let memories = result.array._jsonClass(for: [WWIntelligentAgent.Memory].self)
        return memories
    }
    
    /// 搜尋包含關鍵字的名記憶（使用 LIKE）
    /// - Parameters:
    ///   - keyword: 搜尋關鍵字
    ///   - sessionId: 可選的會話 ID 過濾
    ///   - limit: 最大筆數
    /// - Returns: 符合的記憶陣列
    func searchMemories(keyword: String, sessionId: String? = nil, limit: Int = 20) throws -> [WWIntelligentAgent.Memory]? {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        var whereCondition: WWSQLite3Manager.Where = .init().like(key: "content", pattern: "%\(keyword)%")
        
        if let sessionId = sessionId { whereCondition = whereCondition.and("sessionId", .equal, .text(sessionId)) }
        
        let orderBy: WWSQLite3Manager.OrderBy = .init().build(orderTypes: [(key: "timestamp", direction: .desc)])
        let limitCondition = WWSQLite3Manager.Limit().build(count: limit, offset: 0)
        
        let result = database.select(tableName: tableName, type: WWIntelligentAgent.Memory.self, where: whereCondition, orderBy: orderBy, limit: limitCondition)
        let memories = result.array._jsonClass(for: [WWIntelligentAgent.Memory].self)
        
        return memories
    }
    
    /// 清除某會話的所有記憶
    /// - Parameter sessionId: 會話 ID
    /// - Returns: 是否成功清除
    func clearSessionMemory(sessionId: String) throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        let whereCondition: WWSQLite3Manager.Where = .init().and("sessionId", .equal, .text(sessionId))
        
        do {
            try database.delete(tableName: tableName, where: whereCondition)
        } catch {
            throw error
        }
    }
    
    /// 刪除過期的記憶（例如：超過 30 天）
    /// - Parameter olderThanDays: 天數（預設 30）
    /// - Returns: 是否成功刪除
    func deleteExpiredMemories(olderThanDays: Int = 30) throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }
        guard let currentOffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date()) else { return }
        
        let whereCondition: WWSQLite3Manager.Where = .init().and("timestamp", .lessThan, .text("\(currentOffDate)"))
        
        do {
            try database.delete(tableName: tableName, where: whereCondition)
        } catch {
            throw error
        }
    }
    
    /// 關閉資料庫連線
    func close() throws {
        
        guard let database = database else { throw WWIntelligentAgent.CustomError.databaseNotConnected }

        do {
            try database.close()
        } catch {
            throw error
        }
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
