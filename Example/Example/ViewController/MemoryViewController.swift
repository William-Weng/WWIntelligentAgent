//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/5/20.
//

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
