//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/5/20.
//

import UIKit
import WWIntelligentAgent

final class ViewController: UIViewController {
        
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var streamSwitch: UISwitch!
    
    private let agent = WWIntelligentAgent()
    private let instructions = "You are an assistant that is good at organizing technical highlights."
    private let prompt = "Please explain the purpose of LanguageModelSession."
    
    private var memAgent: IntelligentAgentWithMemory!
    private let sessionId = "session_\(UUID().uuidString)"
    
    private var messages: [String] = [
        "我的名字叫什麼？",
        "我是位iOS打字工",
        "我的名字叫William",
    ]
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure()
        
        memAgent = try! IntelligentAgentWithMemory(agent: .init(), sessionId: "session_E7B3B043-5A68-4633-AAF6-0C8D79E4DE48")
        
        print(sessionId)
        print(URL.documentsDirectory)
    }
    
    @IBAction func chatAction(_ sender: UIButton) {
        
        memory()
        
//        guard let prompt = inputTextView.text, !prompt.isEmpty else { return }
//        outputTextView.text = ""
//        
//        !streamSwitch.isOn ? chat(to: prompt) : streamChat(to: prompt)
    }
    
    func memory() {
        
        guard let prompt = messages.popLast() else { return }
        inputTextView.text = prompt
        
        Task {
            let response = try? await memAgent.chat(prompt)
            outputTextView.text = response
        }
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
