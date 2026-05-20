# [WWIntelligentAgent](https://swiftpackageindex.com/William-Weng)

[![Swift-6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![iOS-26.0](https://img.shields.io/badge/iOS-26.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWIntelligentAgent)
[![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

[English](./README.en.md) | [繁體中文](./README.md)

https://github.com/user-attachments/assets/99b61e86-ea67-4a38-86e0-f3b193620c42

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
.dependencies([.package(url: "https://github.com/William-Weng/WWIntelligentAgent.git", from: "1.1.0")])
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

| Property | Description |
|---|---|
| `model` | The current `system language model` in use |

## 🛠️ Public APIs

| API | Description |
|---|---|
| `init(model:)` | Creates an intelligent agent `instance` |
| `configure(with:tools:)` | Configures instructions and tools, then rebuilds the `session` |
| `chat(to:)` | Sends a `prompt` to the model and returns a complete `response` |
| `streamChat(to:)` | Sends a `prompt` to the model and returns a `streaming response` |

## Example

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

## 🚀 Notes

The `Foundation Models` documentation is currently marked as Beta information, so API details and supported platform behavior may still change before the final system releases.

If your application depends heavily on this capability, it is a good idea to provide model availability messaging, fallback strategies, or alternative flows for devices that do not support Apple Intelligence.
