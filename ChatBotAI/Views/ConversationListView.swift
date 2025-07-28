//
//  ConversationListView.swift
//  ChatBotAI
//
//  Displays list of conversations with proper iOS styling
//

import SwiftUI

struct ConversationListView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @Binding var navigationPath: NavigationPath
    @Binding var isShowingNewChat: Bool
    @Binding var refreshTrigger: Bool
    
    @State private var conversations: [ChatConversation] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var conversationToDelete: ChatConversation?
    @State private var showDeleteConfirmation = false
    @State private var showLastConversationWarning = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            if isLoading {
                loadingView
            } else if conversations.isEmpty {
                emptyStateView
            } else {
                conversationListView
            }
            
            // Floating Action Button (only show when there are conversations)
            if !conversations.isEmpty && !isLoading {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isShowingNewChat = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Circle().fill(.blue))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isDeleting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Deleting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                newChatButton
            }
        }
        .overlay(alignment: .top) {
            // Error banner for deletion errors
            if let error = error {
                ErrorBannerView(error: SupabaseError.databaseError(error.localizedDescription)) {
                    self.error = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            loadConversations()
        }
        .onChange(of: refreshTrigger) { _ in
            loadConversations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .conversationTitleUpdated)) { _ in
            // Refresh conversations when a title is updated
            loadConversations()
        }

                 .alert("Delete Conversation", isPresented: $showDeleteConfirmation) {
             Button("Cancel", role: .cancel) {
                 conversationToDelete = nil
             }
             
             Button("Delete", role: .destructive) {
                 if let conversation = conversationToDelete {
                     deleteConversation(conversation)
                 }
             }
         } message: {
             if let conversation = conversationToDelete {
                 Text("Are you sure you want to delete \"\(conversation.title)\"? This action cannot be undone.")
             }
         }
         .alert("Cannot Delete Last Conversation", isPresented: $showLastConversationWarning) {
             Button("OK", role: .cancel) { }
             Button("Create New Chat") {
                 isShowingNewChat = true
             }
         } message: {
             Text("You need at least one conversation. Create a new chat before deleting this one.")
         }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading conversations...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("No Conversations Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first chat to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button("Start New Chat") {
                    isShowingNewChat = true
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                
                Text("or use the + button above")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var conversationListView: some View {
        List(conversations) { conversation in
            NavigationLink(value: conversation) {
                ConversationRowView(conversation: conversation)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: conversations.count <= 1 ? .cancel : .destructive) {
                    if conversations.count <= 1 {
                        showLastConversationWarning = true
                    } else {
                        conversationToDelete = conversation
                        showDeleteConfirmation = true
                    }
                } label: {
                    Label(conversations.count <= 1 ? "Can't Delete" : "Delete", 
                          systemImage: conversations.count <= 1 ? "info.circle" : "trash")
                }
                .disabled(isDeleting)
                .tint(conversations.count <= 1 ? .orange : .red)
            }
            .contextMenu {
                Button {
                    duplicateConversation(conversation)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                .disabled(isDeleting)
                
                Button {
                    shareConversation(conversation)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(isDeleting)
                
                Divider()
                
                Button(role: conversations.count <= 1 ? .cancel : .destructive) {
                    if conversations.count <= 1 {
                        showLastConversationWarning = true
                    } else {
                        conversationToDelete = conversation
                        showDeleteConfirmation = true
                    }
                } label: {
                    Label(conversations.count <= 1 ? "Can't Delete" : "Delete", 
                          systemImage: conversations.count <= 1 ? "info.circle" : "trash")
                }
                .disabled(isDeleting)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var newChatButton: some View {
        Button {
            isShowingNewChat = true
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.title3)
        }
        .accessibilityLabel("New Chat")
    }
    
    // MARK: - Data Loading
    
    private func loadConversations() {
        Task {
            await refreshConversations()
        }
    }
    
    @MainActor
    private func refreshConversations() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedConversations = try await supabaseService.fetchUserConversations()
            conversations = fetchedConversations.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            self.error = error
            print("❌ Failed to load conversations: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Conversation Actions
    
    private func deleteConversation(_ conversation: ChatConversation) {
        guard conversations.count > 1 else {
            // Show warning instead of silently failing
            showLastConversationWarning = true
            conversationToDelete = nil
            return
        }
        
        isDeleting = true
        
        Task {
            do {
                try await supabaseService.deleteConversation(conversationId: conversation.id)
                
                await MainActor.run {
                    // Remove from local array with animation
                    withAnimation(.easeOut(duration: 0.3)) {
                        conversations.removeAll { $0.id == conversation.id }
                    }
                    
                    // Send notification that conversation was deleted
                    NotificationCenter.default.post(name: .conversationDeleted, object: conversation.id)
                    
                    // Clear deletion state
                    conversationToDelete = nil
                    isDeleting = false
                    
                    print("✅ Conversation deleted from UI")
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                    conversationToDelete = nil
                    isDeleting = false
                    print("❌ Failed to delete conversation: \(error)")
                }
            }
        }
    }
    
    private func duplicateConversation(_ conversation: ChatConversation) {
        // TODO: Implement conversation duplication
        print("🔄 Duplicate conversation: \(conversation.title)")
    }
    
    private func shareConversation(_ conversation: ChatConversation) {
        // TODO: Implement conversation sharing
        print("📤 Share conversation: \(conversation.title)")
    }
}

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: ChatConversation
    @State private var isUpdating = false
    @State private var isDeleting = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(isDeleting ? .secondary : .primary)
                    
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.6)
                            .opacity(0.7)
                    }
                    
                    if isDeleting {
                        Text("Deleting...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(formatDate(conversation.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isDeleting {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
        .opacity(isDeleting ? 0.6 : 1.0)
        .onReceive(NotificationCenter.default.publisher(for: .conversationTitleUpdated)) { _ in
            // Show brief update animation
            withAnimation(.easeInOut(duration: 0.3)) {
                isUpdating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isUpdating = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .conversationDeleted)) { notification in
            // Show deletion animation for this specific conversation
            if let deletedId = notification.object as? UUID, deletedId == conversation.id {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isDeleting = true
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ConversationListView(
        navigationPath: .constant(NavigationPath()),
        isShowingNewChat: .constant(false),
        refreshTrigger: .constant(false)
    )
} 
