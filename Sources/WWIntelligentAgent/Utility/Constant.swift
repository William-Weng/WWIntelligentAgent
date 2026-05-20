//
//  Constant.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

import FoundationModels

// MARK: - enum
public extension WWIntelligentAgent {
    
    /// 使用智慧代理時可能發生的錯誤
    enum CustomError: Error {
        
        case sessionNotFound            // 尚未建立可用的 `LanguageModelSession`
        case promptIsEmpty              // 輸入的提示文字為空，或只包含空白與換行字元
        case modelUnavailable           // 目前裝置無法使用指定的系統語言模型
    }
    
    /// 預設的生成模式選項，方便使用者快速選擇適合的設定
    enum OptionType: Sendable {
        
        case `default`                  // 預設值：init()
        case bot                        // 一般聊天模式：保留自然度與穩定性的平衡
        case write                      // 撰寫模式：增加一些變化，適合文案、摘要、改寫、故事等創作
        case code                       // 程式碼模式：偏保守，降低隨機性，讓輸出更穩定
        case classify                   // 分類模式：使用 greedy，輸出穩定且可重複，適合標籤、類別判斷、資料抽取
    }
}

// MARK: - OptionType
extension WWIntelligentAgent.OptionType {
    
    /// 產生對應的生成模式選項
    /// - Returns: GenerationOptions
    func value() -> GenerationOptions {
        
        switch self {
        case .default: return .init()
        case .bot: return .init(sampling: nil, temperature: 0.7, maximumResponseTokens: 800)
        case .write: return .init(sampling: nil, temperature: 0.9, maximumResponseTokens: 1200)
        case .code: return .init(sampling: nil, temperature: 0.3, maximumResponseTokens: 1000)
        case .classify: return .init(sampling: .greedy, temperature: 0.0, maximumResponseTokens: 100)
        }
    }
}
