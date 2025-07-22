//
//  AIModelSelectorView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

struct AIModelSelectorView: View {
    @ObservedObject var aiService: AIService
    @State private var showingSelector = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Current Model Display
            Button(action: { showingSelector.toggle() }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(modelStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(aiService.selectedModel.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Image(systemName: showingSelector ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Model Selector Dropdown
            if showingSelector {
                VStack(spacing: 4) {
                    ForEach(AIModel.allCases) { model in
                        ModelRowView(
                            model: model,
                            isSelected: model == aiService.selectedModel,
                            isAvailable: aiService.availableModels.contains(model)
                        ) {
                            aiService.switchModel(to: model)
                            showingSelector = false
                        }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingSelector)
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

struct ModelRowView: View {
    let model: AIModel
    let isSelected: Bool
    let isAvailable: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: isAvailable ? onSelect : {}) {
            HStack(spacing: 12) {
                // Status Indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Model Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isAvailable ? .primary : .secondary)
                    
                    if model.isFree {
                        Text("Free")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                // Selected Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                // Unavailable Indicator
                if !isAvailable {
                    Image(systemName: "key.slash")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isAvailable)
    }
    
    private var statusColor: Color {
        if isSelected && isAvailable {
            return .blue
        } else if isAvailable {
            return .green
        } else {
            return .red
        }
    }
}

#Preview {
    VStack {
        AIModelSelectorView(aiService: AIService.shared)
        Spacer()
    }
    .padding()
} 