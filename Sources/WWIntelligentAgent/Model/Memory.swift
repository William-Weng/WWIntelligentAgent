//
//  Memory.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

#if canImport(FoundationModels)
import Foundation
import WWSQLite3Manager

// MARK: - Session
@available(iOS 26.0, *)
public extension WWIntelligentAgent {
    
    /// Agent 記憶模型（中期記憶：跨會話對話歷史）
    struct Memory: Codable {
        
        public var id: Int?                  // SQLite AUTOINCREMENT（主鍵）
        public var sessionId: String         // 會話 ID（區分不同對話）
        public var role: String              // "user" 或 "assistant"
        public var content: String           // 訊息內容
        public var timestamp: Date           // 時間戳
        public var metadata: String?         // 額外資訊（JSON 格式，可選）
        public var embedding: [Float]?       // 向量嵌入（512 維，用於語意搜尋）
    }
}

// MARK: - SchemeDelegate
@available(iOS 26.0, *)
extension WWIntelligentAgent.Memory: WWSQLite3Manager.SchemeDelegate {
    
    public static func structure() -> [(key: String, type: WWSQLite3Manager.DataType)] {
        
        [
            (key: "id", type: .INTEGER()),
            (key: "sessionId", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "role", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "content", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "timestamp", type: .TIMESTAMP()),
            (key: "metadata", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "embedding", type: .BLOB(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
        ]
    }
}

#endif
