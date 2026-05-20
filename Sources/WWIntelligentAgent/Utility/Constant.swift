//
//  Constant.swift
//  WWIntelligentAgent
//
//  Created by William.Weng on 2026/5/20.
//

import Foundation

// MARK: - enum
public extension WWIntelligentAgent {
    
    /// 使用智慧代理時可能發生的錯誤
    enum CustomError: Error {
        case sessionNotFound        // 尚未建立可用的 `LanguageModelSession`
        case promptIsEmpty          // 輸入的提示文字為空，或只包含空白與換行字元
        case modelUnavailable       // 目前裝置無法使用指定的系統語言模型
    }
}
