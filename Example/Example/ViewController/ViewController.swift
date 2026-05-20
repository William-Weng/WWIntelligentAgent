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
