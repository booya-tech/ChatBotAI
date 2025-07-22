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
    case huggingFaceLlama = "meta-llama/Llama-2-7b-chat-hf"
    case geminiFlash = "gemini-1.5-flash"
    case groqLlama = "llama-3.1-8b-instant"
    case groqMixtral = "mixtral-8x7b-32768"
    case mockAI = "mock-ai"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .huggingFaceLlama: return "Llama 2 7B (Hugging Face)"
        case .geminiFlash: return "Gemini 1.5 Flash (Google)"
        case .groqLlama: return "Llama 3.1 8B (Groq)"
        case .groqMixtral: return "Mixtral 8x7B (Groq)"
        case .mockAI: return "Mock AI (Hardcoded)"
        }
    }
    
    var provider: AIProviderType {
        switch self {
        case .huggingFaceLlama: return .huggingFace
        case .geminiFlash: return .google
        case .groqLlama, .groqMixtral: return .groq
        case .mockAI: return .mock
        }
    }
    
    var isFree: Bool {
        switch self {
        case .huggingFaceLlama, .geminiFlash, .groqLlama, .groqMixtral, .mockAI:
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
    
    @Published var selectedModel: AIModel = .huggingFaceLlama
    @Published var isGenerating = false
    @Published var error: AIError?
    
    private var providers: [AIProviderType: AIProvider] = [:]
    
    private init() {
        setupProviders()
    }
    
    private func setupProviders() {
        providers[.huggingFace] = HuggingFaceProvider()
        providers[.groq] = GroqProvider()
        providers[.mock] = MockAIProvider()
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
        selectedModel = model
        print("🔄 Switched to AI model: \(model.displayName)")
    }
    
    var availableModels: [AIModel] {
        AIModel.allCases.filter { model in
            providers[model.provider]?.isAvailable ?? false
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