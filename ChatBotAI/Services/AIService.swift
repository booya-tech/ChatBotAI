//
//  AIService.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import Foundation

// MARK: - AI Provider Protocol

protocol AIProvider {
    var name: String { get }
    var model: String { get }
    var isAvailable: Bool { get }
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message]
    ) async throws -> String
}

// MARK: - AI Models Enum

enum AIModel: String, CaseIterable, Identifiable {
    case huggingFaceDialo = "microsoft/DialoGPT-small"
    case geminiFlash = "gemini-1.5-flash"
    case groqLlama = "llama-3.1-8b-instant"
    case groqMixtral = "mixtral-8x7b-32768"
    case mockAI = "mock-ai"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .huggingFaceDialo: return "DialoGPT Small (Hugging Face)"
        case .geminiFlash: return "Gemini 1.5 Flash (Google)"
        case .groqLlama: return "Llama 3.1 8B (Groq)"
        case .groqMixtral: return "Mixtral 8x7B (Groq)"
        case .mockAI: return "Mock AI (Hardcoded)"
        }
    }
    
    var provider: AIProviderType {
        switch self {
        case .huggingFaceDialo: return .huggingFace
        case .geminiFlash: return .google
        case .groqLlama, .groqMixtral: return .groq
        case .mockAI: return .mock
        }
    }
    
    var isFree: Bool {
        switch self {
        case .huggingFaceDialo, .geminiFlash, .groqLlama, .groqMixtral, .mockAI:
            return true
        }
    }
}

enum AIProviderType {
    case huggingFace, google, groq, mock
}

// MARK: - AI Service

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var selectedModel: AIModel = .groqLlama
    @Published var isGenerating = false
    @Published var error: AIError?
    
    private var providers: [AIProviderType: AIProvider] = [:]
    
    private init() {
        setupProviders()
        selectBestAvailableModel()
    }
    
    private func setupProviders() {
        providers[.huggingFace] = HuggingFaceProvider()
        providers[.groq] = GroqProvider()
        providers[.google] = MockAIProvider() // Placeholder until GoogleGeminiProvider is added
        providers[.mock] = MockAIProvider()
    }
    
    private func selectBestAvailableModel() {
        // Priority order: Groq (fastest/most reliable) > Hugging Face > Mock AI
        let preferredModels: [AIModel] = [.groqLlama, .huggingFaceDialo, .mockAI]
        
        for model in preferredModels {
            if let provider = providers[model.provider], provider.isAvailable {
                selectedModel = model
                print("🎯 Auto-selected \(model.displayName) as default AI model")
                return
            }
        }
        
        // Fallback to any available model
        if let firstAvailable = availableModels.first {
            selectedModel = firstAvailable
            print("🎯 Fallback selected \(firstAvailable.displayName) as default AI model")
        }
    }
    
    // MARK: - Public Methods
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message] = []
    ) async throws -> String {
        isGenerating = true
        error = nil
        
        defer { isGenerating = false }
        
        guard let provider = providers[selectedModel.provider] else {
            throw AIError.providerNotAvailable
        }
        
        guard provider.isAvailable else {
            throw AIError.providerNotConfigured(selectedModel.displayName)
        }
        
        do {
            let response = try await provider.generateResponse(
                for: message,
                conversationHistory: conversationHistory
            )
            return response
        } catch {
            self.error = AIError.generationFailed(error.localizedDescription)
            throw error
        }
    }
    
    func switchModel(to model: AIModel) {
        let oldModel = selectedModel
        selectedModel = model
        print("🔄 Switched AI model from \(oldModel.displayName) to \(model.displayName)")
        print("🔍 Available models: \(availableModels.map { $0.displayName })")
    }
    
    var availableModels: [AIModel] {
        AIModel.allCases.filter { model in
            if let provider = providers[model.provider] {
                return provider.isAvailable
            } else {
                // If no provider is set up, still allow Mock AI
                return model == .mockAI
            }
        }
    }
}

// MARK: - Error Types

enum AIError: LocalizedError {
    case providerNotAvailable
    case providerNotConfigured(String)
    case generationFailed(String)
    case invalidResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .providerNotAvailable:
            return "AI provider not available"
        case .providerNotConfigured(let provider):
            return "\(provider) not configured. Please add API key."
        case .generationFailed(let error):
            return "Failed to generate response: \(error)"
        case .invalidResponse:
            return "Invalid response from AI provider"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        }
    }
}

// MARK: - Mock AI Provider (Fallback)

class MockAIProvider: AIProvider {
    let name = "Mock AI"
    let model = "mock-ai"
    let isAvailable = true
    
    func generateResponse(
        for message: String,
        conversationHistory: [Message]
    ) async throws -> String {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let responses = [
            "That's an interesting question! Let me think about that.",
            "I understand what you're asking. Here's my perspective on that.",
            "Thanks for sharing that with me. I'd be happy to help!",
            "That's a great point. Let me elaborate on that topic.",
            "I see what you mean. Here's how I would approach that.",
            "Absolutely! That's something I can definitely help you with.",
            "Good question! Let me break that down for you.",
            "I appreciate you asking about that. Here's what I think.",
            "Based on what you're saying, I think the best approach would be...",
            "Let me help you with that. Here's what I recommend..."
        ]
        
        return responses.randomElement() ?? "I'm here to help!"
    }
} 
