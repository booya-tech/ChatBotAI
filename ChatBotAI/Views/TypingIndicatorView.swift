//
//  TypingIndicatorView.swift
//  ChatBotAI
//
//  Created by Panachai Sulsaksakul on 7/14/25.
//

import SwiftUI

struct TypingIndicatorView: View {
    let isTyping: Bool
    
    var body: some View {
        if isTyping {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(isTyping ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: isTyping
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                    )
                    
                    Text("AI is typing...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 60)
            }
            .id("loading")
        }
    }
} 