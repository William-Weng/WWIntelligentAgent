//
//  HistoryPrefixWord.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/29.
//

#if canImport(FoundationModels)
import Foundation

// MARK: - History Prefix Word
@available(iOS 26.0, *)
public extension WWIntelligentAgent {
    
    /// 定義對話歷史提示字 possu 的前綴用詞 => 用於組合 prompt 時，標示不同區塊的標題
    struct HistoryPrefixWord {
        
        let title: String
        let relevantMemories: String
        let null: String
        
        /// 初始化歷史前綴用詞
        ///
        /// - Parameters:
        ///   - title: 對話歷史標題，預設 `"Conversation History"`
        ///   - relevantMemories: 相關記憶標題，預設 `"Relevant Memories"`
        ///   - null: 空區塊提示，預設 `"None"`
        public init(title: String = "Conversation History", relevantMemories: String = "Relevant Memories", null: String = "None") {
            self.title = title
            self.relevantMemories = relevantMemories
            self.null = null
        }
    }
}
#endif
