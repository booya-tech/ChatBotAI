//
//  AIModelSelectorView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

struct AIModelSelectorView: View {
    @ObservedObject var aiService: AIService
    
    var body: some View {
        Button(action: toggleModel) {
            HStack(spacing: 8) {
                Circle()
                    .fill(modelStatusColor)
                    .frame(width: 8, height: 8)
                
                Text(aiService.selectedModel.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    private func toggleModel() {
        let availableModels = aiService.availableModels
        guard !availableModels.isEmpty else { return }
        
        if let currentIndex = availableModels.firstIndex(of: aiService.selectedModel) {
            let nextIndex = (currentIndex + 1) % availableModels.count
            let nextModel = availableModels[nextIndex]
            print("🔄 Toggling from \(aiService.selectedModel.displayName) to \(nextModel.displayName)")
            aiService.switchModel(to: nextModel)
        } else {
            // If current model not in available list, switch to first available
            aiService.switchModel(to: availableModels.first!)
        }
    }
    
    private var modelStatusColor: Color {
        if aiService.isGenerating {
            return .orange
        } else if aiService.availableModels.contains(aiService.selectedModel) {
            return .green
        } else {
            return .red
        }
    }
}