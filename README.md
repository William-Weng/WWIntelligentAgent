# [WWIntelligentAgent](https://swiftpackageindex.com/William-Weng)

[![Swift-6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![iOS-26.0](https://img.shields.io/badge/iOS-26.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWIntelligentAgent)
[![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

[English](./README.en.md) | [繁體中文](./README.md)

https://github.com/user-attachments/assets/2898608e-e952-426f-9ef9-e9457a685be6

---

## 🎉  相關說明
一個以 **Apple Foundation Models** 為基礎的輕量級 Swift 包裝器，用來簡化 `SystemLanguageModel`、`LanguageModelSession`、提示文字驗證，以及一般回應與串流回應的呼叫流程。

此套件的目標是把重複的 session 建立、模型可用性檢查與 prompt 驗證集中管理，讓專案更容易維護，也讓對外 API 保持乾淨一致。

## ✨ 功能特色

- 封裝 `SystemLanguageModel` 與 `LanguageModelSession` 的建立流程，減少重複樣板程式碼。
- 在送出請求前統一檢查模型是否可用，符合 Apple 對 Foundation Models 的使用建議。
- 集中驗證提示文字，避免空白字串或只有換行的內容被送入模型。
- 同時提供完整回應與串流回應的呼叫方式，適合聊天、摘要、內容產生等情境。
- 可透過 `instructions` 與 `tools` 重新建立 session，便於擴充工具呼叫與自訂模型行為。

## 🧠 設計重點

`LanguageModelSession` 代表一個會保留上下文狀態的對話 session，因此適合被重複使用，而不是每次呼叫都重新拆散流程處理。

此封裝將常見的前置檢查拆成幾個責任明確的方法，例如 session 驗證、prompt 驗證與 session 重建，讓主要對話 API 專注在協調流程本身。

## 📦 安裝方式

將套件加入 `Package.swift`：

```swift
.dependencies([.package(url: "https://github.com/William-Weng/WWIntelligentAgent.git", from: "1.3.0")])
```

然後在 target 中加入：

```swift
.target(
    name: "<YourTarget>",
    dependencies: ["WWIntelligentAgent"]
)
```

如果是使用 Xcode，也可以透過 **File > Add Package Dependencies...** 加入 GitHub 倉庫。

## 📖 公開屬性

| 屬性 (WWIntelligentAgent) | 說明 |
|---|---|
| `model` | 目前使用的`系統語言模型` |

## 🛠️ 公開 API

| API (WWIntelligentAgent) | 說明 |
|---|---|
| `init(model:)` | 建立一個智慧代理`實例` |
| `configure(with:tools:optionType:)` | 設定系統指令與工具，並重新建立`工作階段` |
| `chat(to:)` | 傳送`提示文字`給模型，並取得完整`回應結果` |
| `streamChat(to:)` | 傳送`提示文字`給模型，並以`串流方式`取得回應結果 |

| API (WWIntelligentAgentWithMemory) | 說明 |
|---|---|
| `init(agent:sessionId:historyPrefixWord:)` | 初始化含記憶功能的Agent |
| `chat(to:limit:useSemanticSearch:similarLimit:)` | 傳送提示文字給模型，並取得完整回應結果，自動保存記憶 |
| `streamChat(to:limit:useSemanticSearch:similarLimit:)` | 傳送提示文字給模型，以串流方式取得回應，並自動保存完整記憶 |
| `saveAssistantMemory(_:)` | 儲存 AI 助理的對話記憶 |
| `searchMemory(keyword:)` | 搜尋歷史對話記憶 |

## 🚀 基本對話

```swift
import UIKit
import WWIntelligentAgent

final class TalkViewController: UIViewController {
    
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var streamSwitch: UISwitch!
    
    private let agent = WWIntelligentAgent()
    private let instructions = "You are an assistant that is good at organizing technical highlights."
    private let prompt = "Please explain the purpose of LanguageModelSession."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    @IBAction func chatAction(_ sender: UIButton) {
        
        guard let prompt = inputTextView.text, !prompt.isEmpty else { return }
        outputTextView.text = ""
        
        !streamSwitch.isOn ? chat(to: prompt) : streamChat(to: prompt)
    }
}

private extension TalkViewController {
    
    func configure() {
        agent.configure(with: instructions)
    }
    
    func chat(to prompt: String) {
        
        Task {
            do {
                let content = try await agent.chat(to: prompt)
                outputTextView.text = content
            } catch {
                outputTextView.text = error.localizedDescription
            }
        }
    }
    
    func streamChat(to prompt: String) {
    
        Task {
            do {
                for try await partial in try await agent.streamChat(to: prompt) {
                    outputTextView.text = partial.content
                }
            } catch {
                print(error)
            }
        }
    }
}
```

## 🚀 基本對話 (有記憶功能)

```swift
import UIKit
import WWIntelligentAgent

final class MemoryViewController: UIViewController {
        
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var streamSwitch: UISwitch!

    private let sessionId = "session_E7B3B043-5A68-4633-AAF6-0C8D79E4DE48"
    
    private var agent: WWIntelligentAgentWithMemory!
    
    private var messages: [String] = [
        "我的名字叫什麼？",
        "我是位iOS打字工",
        "我的名字叫William",
    ]

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMemory()
    }
    
    @IBAction func chatAction(_ sender: UIButton) {

        guard let prompt = messages.popLast() else { return }
        
        inputTextView.text = prompt
        outputTextView.text = ""
                
        if !streamSwitch.isOn { chat(to: prompt); return }
        Task { try? await streamChat(to: prompt) }
    }
}

private extension MemoryViewController {
    
    func initMemory() {
        
        let intelligentAgent: WWIntelligentAgent = .init(model: .default)
        intelligentAgent.configure(with: "我是位很好聊天的好幫手，可以記住別人的說話，下次再和我说什麼，我可以記住哦，而且簡化問題。", optionType: .bot)
        
        do {
            agent = try WWIntelligentAgentWithMemory(agent: intelligentAgent, sessionId: sessionId)
        } catch {
            outputTextView.text = error.localizedDescription
        }
    }
    
    func chat(to prompt: String) {
        
        Task {
            let response = try await agent.chat(to: prompt)
            outputTextView.text = response
            
            do {
                try await agent.saveAssistantMemory(response)
            } catch {
                outputTextView.text = error.localizedDescription
            }
        }
    }
    
    func streamChat(to prompt: String) async throws {
                
        for try await partial in try await agent.streamChat(to: prompt) {
            Task { @MainActor in outputTextView.text = partial.content }
        }
        
        if let response = outputTextView.text { try await agent.saveAssistantMemory(response) }
    }
}
```

## 🧰 可用工具 

| 工具 | 版本 | 說明 |
|---|---|---|
| [`WWHttpFetchTool`](https://github.com/William-Weng/WWHttpFetchTool) | ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWHttpFetchTool)  | 輕量級 HTTP 請求工具，用於發送網路請求並擷取回應內容，最終以純文字格式提供給 Apple Intelligence 進行後續分析。 |
| [`WWTextReaderTool`](https://github.com/William-Weng/WWTextReaderTool) | ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWNtpClientTool)  |  檔案讀取工具，負責存取 Documents 目錄中的檔案，並將其文字內容轉換為可供 Apple Intelligence 處理的輸入資料。 |
| [`WWNtpClientTool`](https://github.com/William-Weng/WWNtpClientTool) | ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWNtpClientTool)  |  網路時間查詢工具，透過 NTP（Network Time Protocol）取得精確的當前時間資訊。 |

## ⚠️ 注意事項

`Foundation Models` 文件目前仍標示為 Beta 資訊，相關 API 與可用平台細節在正式版系統推出前仍可能調整。

如果應用程式高度依賴此功能，建議在產品層面加入模型可用性提示、降級策略，或在不支援 Apple Intelligence 的裝置上提供替代流程。

