//
//  Memory.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/27.
//

import Foundation
import WWSQLite3Manager

// MARK: - Session
extension WWIntelligentAgent {
    
    /// Agent 記憶模型（中期記憶：跨會話對話歷史）
    struct Memory: Codable {
        
        var id: Int?                  // SQLite AUTOINCREMENT（主鍵）
        var sessionId: String         // 會話 ID（區分不同對話）
        var role: String              // "user" 或 "assistant"
        var content: String           // 訊息內容
        var timestamp: Date           // 時間戳
        var metadata: String?         // 額外資訊（JSON 格式，可選）
    }
}

// MARK: - SchemeDelegate
extension WWIntelligentAgent.Memory: WWSQLite3Manager.SchemeDelegate {
    
    static func structure() -> [(key: String, type: WWSQLite3Manager.DataType)] {
        
        [
            (key: "id", type: .INTEGER()),
            (key: "sessionId", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "role", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "content", type: .TEXT(attribute: (isNotNull: true, isNoCase: false, isUnique: false), defaultValue: nil)),
            (key: "timestamp", type: .TIMESTAMP()),
            (key: "metadata", type: .TEXT(attribute: (isNotNull: false, isNoCase: false, isUnique: false), defaultValue: nil)),
        ]
    }
}
