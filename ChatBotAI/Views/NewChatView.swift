//
//  NewChatView.swift
//  ChatBotAI
//
//  Modal sheet for creating new conversations
//

import SwiftUI

struct NewChatView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var aiService = AIService.shared
    
    @Binding var isPresented: Bool
    @Binding var navigationPath: NavigationPath
    
    let onConversationCreated: () -> Void
    
    @State private var conversationTitle = ""
    @State private var isCreating = false
    @State private var error: Error?
    
    // Pre-defined conversation starters
    private let conversationStarters = [
        "General Chat",
        "Creative Writing",
        "Code Help",
        "Learning & Study",
        "Problem Solving",
        "Brainstorming"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                titleInputSection
                
                if !isCreating {
                    conversationStartersSection
                } else {
                    creatingSection
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Create") {
                            createConversation()
                        }
                        .disabled(conversationTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Start a New Conversation")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a title for your chat or select from the suggestions below")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var titleInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conversation Title")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Enter a title...", text: $conversationTitle)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    if !conversationTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        createConversation()
                    }
                }
        }
    }
    
    private var conversationStartersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Suggestions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(conversationStarters, id: \.self) { starter in
                    Button(starter) {
                        conversationTitle = starter
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var creatingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Creating your conversation...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
    
    // MARK: - Actions
    
    private func createConversation() {
        let title = conversationTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        isCreating = true
        error = nil
        
        Task {
            do {
                // Create new conversation
                let newConversation = try await supabaseService.createConversation(title: title)
                
                // Generate welcome message using AI
                let welcomeMessage = try await aiService.generateResponse(
                    for: "Please introduce yourself as a helpful AI assistant and ask how you can help with \(title)."
                )
                
                // Add welcome message to conversation
                _ = try await supabaseService.sendAIResponse(
                    conversationId: newConversation.id,
                    content: welcomeMessage
                )
                
                await MainActor.run {
                    // Navigate to the new conversation
                    navigationPath.append(newConversation)
                    
                    // Notify parent to refresh conversation list
                    onConversationCreated()
                    
                    // Close the sheet
                    isPresented = false
                    isCreating = false
                    
                    print("✅ New conversation created: \(newConversation.title)")
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                    isCreating = false
                    print("❌ Failed to create conversation: \(error)")
                }
            }
        }
    }
}

#Preview {
    NewChatView(
        isPresented: .constant(true),
        navigationPath: .constant(NavigationPath()),
        onConversationCreated: {}
    )
} 