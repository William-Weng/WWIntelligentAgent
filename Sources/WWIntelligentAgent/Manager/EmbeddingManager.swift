//
//  EmbeddingManager.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/28.
//

import Foundation

import Foundation
import NaturalLanguage
import WWSQLite3Manager

// MARK: - Memory Embedding Manager
extension WWIntelligentAgent {
    
    /// 管理對話記憶的向量嵌入（Embedding）計算與儲存
    ///
    /// 使用 `NLEmbedding`（Apple 自然語言框架）建立語句向量：
    /// - 將記憶文字轉成高維向量
    /// - 用於語意相似度計算、語意搜尋、記憶分檢
    ///
    /// 使用 `actor` 確保：
    /// - Embedding 計算與儲存是 ** concurrency-safe **
    /// - 多任務同時呼叫時不會有競爭條件
    final actor EmbeddingManager {
        
        private let embedding: NLEmbedding      // 底層語句向量嵌入器 => 負責將文字轉成向量（array of Double）
        
        /// 初始化流程
        /// - Parameter language: 要處理的語系（NLLanguage），例如 .chinese, .english
        /// - Throws: 當找不到對應語系的 sentence embedding 模型時拋出 `CustomError.NLLanguageFailed`
        init(for language: NLLanguage) throws {
            
            if let embedding = NLEmbedding.sentenceEmbedding(for: language) {
                self.embedding = embedding
            } else {
                throw CustomError.NLLanguageFailed
            }
        }
    }
}

// MARK: - 小工具
extension WWIntelligentAgent.EmbeddingManager {
        
    /// 將文字轉換為向量嵌入 => Float省資源
    /// - Parameter text: 要轉換的文字
    /// - Returns: 512 維的 Float 陣列
    func embed(_ text: String) -> [Float] {
        guard let vector = embedding.vector(for: text) else { return [] }
        return vector.map { Float($0) }
    }
    
    /// 計算兩個向量的餘弦相似度
    /// - Parameters:
    ///   - vector1: 第一個向量
    ///   - vector2: 第二個向量
    /// - Returns: 相似度分數（-1 到 1 之間，1 表示完全相同）
    func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {

        guard vector1.count == vector2.count,
              !vector1.isEmpty
        else {
            return 0
        }
        
        var dotProduct: Float = 0
        var norm1: Float = 0
        var norm2: Float = 0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            norm1 += vector1[i] * vector1[i]
            norm2 += vector2[i] * vector2[i]
        }
        
        let magnitude = sqrt(norm1) * sqrt(norm2)
        guard magnitude != 0 else { return 0 }
        
        return dotProduct / magnitude
    }
    
    /// 批次計算餘弦相似度（用於向量搜尋）
    /// - Parameters:
    ///   - queryVector: 查詢向量
    ///   - storedVectors: 已儲存的向量陣列
    /// - Returns: [(index: Int, similarity: Float)] 依相似度排序
    func batchCosineSimilarity(_ queryVector: [Float], _ storedVectors: [[Float]]) -> [(index: Int, similarity: Float)] {
        
        var results: [(index: Int, similarity: Float)] = []
        
        for (index, vector) in storedVectors.enumerated() {
            let similarity = cosineSimilarity(queryVector, vector)
            results.append((index: index, similarity: similarity))
        }
        
        return results.sorted { $0.similarity > $1.similarity }
    }
}

// MARK: - Memory Extension with Embedding
//public extension WWIntelligentAgent.Memory {
    
    /// 將 Memory 轉為 Data（包含 embedding）
    ///
//    @MainActor
//    var embeddingData: Data? {
//        guard let embedding = self.embedding else { return nil }
//        return WWIntelligentAgent.EmbeddingManager.shared.embeddingToData(embedding)
//    }
//}

// MARK: - Usage Example
/*
 // 新增對話時自動計算 Embedding
 let content = "你好，如何重設密碼？"
 let embedding = MemoryEmbeddingManager.shared.embed(content)
 
 let memory = WWIntelligentAgent.Memory(
     sessionId: "session_123",
     role: "user",
     content: content,
     timestamp: Date(),
     embedding: embedding
 )
 
 // 寫入 SQLite
 try await db.insert(memory)
 
 // 查詢時計算相似度
 let query = "密碼忘記怎麼辦"
 let queryVector = MemoryEmbeddingManager.shared.embed(query)
 
 let storedVectors: [[Float]] = [...]  // 從資料庫讀取
 let results = MemoryEmbeddingManager.shared.batchCosineSimilarity(queryVector, storedVectors)
 */
