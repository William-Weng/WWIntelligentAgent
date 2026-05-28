# [WWIntelligentAgent](https://swiftpackageindex.com/William-Weng)

[![Swift-6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![iOS-26.0](https://img.shields.io/badge/iOS-26.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWIntelligentAgent)
[![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

[English](./README.en.md) | [繁體中文](./README.md)

https://github.com/user-attachments/assets/2898608e-e952-426f-9ef9-e9457a685be6

---

## 🎉 Overview
A lightweight Swift wrapper built on **Apple Foundation Models** that simplifies `SystemLanguageModel`, `LanguageModelSession`, prompt validation, and both standard and streaming response workflows.

The goal of this package is to centralize repeated session creation, model availability checks, and prompt validation so the codebase stays easier to maintain and the public API remains clean and consistent.[cite:82]

## ✨ Features

- Wraps the setup flow of `SystemLanguageModel` and `LanguageModelSession` to reduce boilerplate code.
- Performs a unified model availability check before requests, following Apple's Foundation Models guidance.
- Centralizes prompt validation to prevent empty or whitespace-only input from being sent to the model.
- Supports both full responses and streaming responses, which is useful for chat, summarization, and content generation scenarios.
- Rebuilds sessions with `instructions` and `tools`, making it easier to extend tool calling and customize model behavior.

## 🧠 Design Highlights

`LanguageModelSession` represents a conversational session that keeps contextual state, so it is well suited for reuse instead of rebuilding the entire flow on every request.

This wrapper separates common preflight checks into focused methods such as session validation, prompt validation, and session rebuilding, allowing the main chat APIs to stay focused on orchestration.

## 📦 Installation

Add the package to your `Package.swift`:

```swift
.dependencies([.package(url: "https://github.com/William-Weng/WWIntelligentAgent.git", from: "1.2.3")])
```

Then add it to your target:

```swift
.target(
    name: "<YourTarget>",
    dependencies: ["WWIntelligentAgent"]
)
```

If you are using Xcode, you can also add the GitHub repository through **File > Add Package Dependencies...**.

## 📖 Public Properties

| Property (WWIntelligentAgent) | Description |
|---|---|
| `model` | The current `system language model` in use |

## 🛠️ Public APIs

| API (WWIntelligentAgent) | Description |
|---|---|
| `init(model:)` | Creates an intelligent agent `instance` |
| `configure(with:tools:)` | Configures instructions and tools, then rebuilds the `session` |
| `chat(to:)` | Sends a `prompt` to the model and returns a complete `response` |
| `streamChat(to:)` | Sends a `prompt` to the model and returns a `streaming response` |

| API (MemoryManager) | Description |
|---|---|
| `init(databaseName:tableName:)` | Creates a MemoryManager instance and specifies the database name and table name. |
| `connect()` | Connects to the SQLite database. |
| `createTableIfNotExists()` | Creates the memory table if it does not already exist. |
| `saveMemory(sessionId:role:content:metadata:)` | Saves a single memory record. |
| `memoryHistory(sessionId:limit:)` | Retrieves the memory history for a specified session. |
| `recentMemories(limit:)` | Retrieves the most recent N memory records. |
| `searchMemories(keyword:sessionId:limit:)` | Searches memories by keyword, optionally limited to a specific session. |
| `clearSessionMemory(sessionId:)` | Clears all memories for a specific session. |
| `deleteExpiredMemories(olderThanDays:)` | Deletes expired memories older than the specified number of days. |
| `close()` | Closes the database connection. |

| `API (WWIntelligentAgentWithMemory)` | Description |
|---|---|
| `init(agent:sessionId:historyPrefixWord:)` | Initializes an Agent with memory functionality. |
| `chat(to:limit:)` | Sends a prompt to the model and returns the complete response, automatically saving memory. |
| `streamChat(to:limit:onUpdate:)` | Sends a prompt to the model, receives the response via streaming, and automatically saves the complete memory. |
| `saveAssistantMemory(_:)` | Saves the conversation memory of the AI assistant. |
| `searchMemory(keyword:)` | Searches through the historical conversation memory. |

## 🚀 Example 1

```swift
import UIKit
import WWIntelligentAgent

final class ViewController: UIViewController {
    
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

private extension ViewController {
    
    func configure() {
        agent.configure(with: instructions)
    }
    
    func chat(to prompt: String) {
        
        Task {
            do {
                let content = try await agent.chat(to: prompt)
                outputTextView.text = content
            } catch {
                print(error)
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

## 🚀 Example 2

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
        
        if !streamSwitch.isOn { chat(to: prompt); return }
        Task { try? await streamChat(to: prompt) }
    }
}

private extension MemoryViewController {
    
    func initMemory() {
        
        do {
            agent = try WWIntelligentAgentWithMemory(agent: .init(), sessionId: sessionId)
        } catch {
            print(error)
        }
    }
    
    func chat(to prompt: String) {
        
        Task {
            let response = try await agent.chat(to: prompt)
            outputTextView.text = response
            
            try agent.saveAssistantMemory(response)
        }
    }
    
    func streamChat(to prompt: String) async throws {
                
        for try await snapshot in try await agent.streamChat(to: prompt) {
            Task { @MainActor in self.outputTextView.text = snapshot.content }
        }
        
        if let response = outputTextView.text { try agent.saveAssistantMemory(response) }
    }
}
```

## 🚀 Notes

The `Foundation Models` documentation is currently marked as Beta information, so API details and supported platform behavior may still change before the final system releases.

If your application depends heavily on this capability, it is a good idea to provide model availability messaging, fallback strategies, or alternative flows for devices that do not support Apple Intelligence.
