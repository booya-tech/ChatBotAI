# ChatBot AI

A modern iOS chat application built with SwiftUI that integrates multiple AI providers for intelligent conversations. Features real-time messaging, conversation management, and secure API key handling.

## Features

- **Multi-AI Provider Support**: Choose between Groq and Mock AI
- **Real-time Chat Interface**: Smooth messaging experience with typing indicators
- **Conversation Management**: Persistent chat history with Supabase backend
- **Anonymous Authentication**: Quick start without account creation
- **API Testing Tools**: Built-in token validation and provider switching
- **Modern UI**: Clean SwiftUI interface with dark mode support
- **Secure Configuration**: Git-safe API key management

## Technology Stack

- **Frontend**: SwiftUI, iOS 15+
- **Backend**: Supabase (Database, Authentication)
- **AI Providers**: 
  - Groq (Llama models)
  - Mock AI (Development/Fallback)
- **Architecture**: MVVM with Swift Concurrency
- **State Management**: Combine framework

## Prerequisites

- Xcode 14.0 or later
- iOS 16.0 or later
- Swift 5.7 or later

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/ChatBotAI.git
cd ChatBotAI
```

### 2. Configure API Keys

#### Create your secure API keys file:
```bash
cp ChatBotAI/Config/APIKeys.template.swift ChatBotAI/Config/APIKeys.swift
```

#### Add your API keys to `ChatBotAI/Config/APIKeys.swift`:
```swift
struct APIKeys {
    // Get from: https://console.groq.com/keys
    static let groqAPIKey = "gsk_your_groq_api_key_here"
}
```

#### Add APIKeys.swift to Xcode:
1. Right-click on "Config" folder in Xcode
2. Select "Add Files to ChatBotAI..."
3. Choose the `APIKeys.swift` file
4. Click "Add"

### 3. Configure Supabase

#### Update `ChatBotAI/Config/SupabaseConfig.swift`:
```swift
static let projectURL = "https://your-project-id.supabase.co"
static let anonKey = "your_supabase_anon_key"
```

#### Set up Supabase database:
1. Create a new Supabase project
2. Run the SQL schema from `database/supabase_setup.sql`
3. Copy your project URL and anon key to the config

### 4. Build and Run

Open `ChatBotAI.xcodeproj` in Xcode and run the project on a simulator or device.

## Project Structure

```
ChatBotAI/
├── ChatBotAI/
│   ├── ChatBotAIApp.swift          # Main app entry point
│   ├── ContentView.swift           # Primary chat interface
│   ├── Config/
│   │   ├── AIConfig.swift          # AI provider configuration
│   │   ├── SupabaseConfig.swift    # Database configuration
│   │   ├── APIKeys.template.swift  # Template for API keys
│   │   └── APIKeys.swift           # Your actual keys (gitignored)
│   ├── Models/
│   │   ├── ChatModels.swift        # Data models
│   │   └── NotificationNames.swift # App notifications
│   ├── Services/
│   │   ├── AIService.swift         # AI provider management
│   │   ├── SupabaseService.swift   # Database operations
│   │   ├── MockSupabaseService.swift # Development service
│   │   └── AI Providers/
│   │       └── GroqProvider.swift  # Groq API integration
│   └── Views/
│       ├── AIModelSelectorView.swift
│       ├── ChatDetailView.swift
│       ├── ChatInputView.swift
│       ├── ConversationListView.swift
│       ├── ConversationNavigationView.swift
│       ├── ErrorBannerView.swift
│       ├── NewChatView.swift
│       └── TypingIndicatorView.swift
├── database/
│   └── supabase_setup.sql          # Database schema
└── SECURITY_SETUP.md               # Security configuration guide
```

## Usage

### Starting a Chat

1. Launch the app
2. The app will automatically sign in anonymously
3. Create a new chat or select an existing conversation
4. Start typing in the input field at the bottom
5. Messages are automatically saved to your conversation history

### Managing Conversations

1. **View Conversations**: Browse your chat history in the main list
2. **Create New Chat**: Tap the "+" button or "New Chat" 
3. **Delete Conversations**: Swipe left on any conversation (except the last one)
4. **Auto-Generated Titles**: Chat titles are automatically created from your first message

### Switching AI Models

1. Tap the AI model selector in the top-right corner of any chat
2. Choose from available providers:
   - **Groq Llama 3.1 8B**: Fast, high-quality responses
   - **Groq Mixtral 8x7B**: Alternative Groq model
   - **Mock AI**: For development and testing

### Testing API Connections

1. Tap "Test APIs" in the navigation bar
2. View the status of all configured providers
3. The app will auto-switch to working providers if others fail

## API Provider Setup

### Groq API
1. Visit [Groq Console](https://console.groq.com/keys)
2. Create an account and generate an API key
3. Free tier: 30 requests per minute
4. Fast inference with Llama models

### Supabase
1. Create a project at [Supabase](https://supabase.com)
2. Set up the database schema using `database/supabase_setup.sql`
3. Enable anonymous authentication in Authentication settings

## Development

### Architecture

The app follows MVVM architecture with SwiftUI:

- **Models**: Data structures for chat messages and conversations
- **Views**: SwiftUI components for the user interface  
- **Services**: Business logic and external API communication
- **ViewModels**: State management and data binding

### Key Components

- **AIService**: Manages AI provider selection and response generation
- **SupabaseService**: Handles database operations and authentication
- **ConversationNavigationView**: Main navigation controller
- **ChatDetailView**: Individual chat interface with message list and input
- **ConversationListView**: Chat history and conversation management

### Navigation Architecture

- **NavigationStack**: Modern iOS navigation with proper back button support
- **Selection-based Navigation**: Efficient conversation switching
- **Deep Linking**: Support for direct chat navigation

### Adding New AI Providers

1. Create a new provider class conforming to `AIProvider` protocol
2. Add the provider to `AIModel` enum in `AIService.swift`
3. Update provider setup in `setupProviders()` method
4. Add configuration and validation to `AIConfig.swift`

## Security

- API keys are stored in a gitignored file (`APIKeys.swift`)
- Supabase handles secure authentication and data storage
- All API communications use HTTPS
- No sensitive data is hardcoded in the repository
- Anonymous authentication persists across app launches

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

1. Follow the setup instructions above
2. Use your own API keys for testing
3. Ensure all tests pass before submitting PRs
4. Follow Swift coding conventions and SwiftUI best practices

## Troubleshooting

### Common Issues

**Build Errors**: Ensure `APIKeys.swift` exists and is added to the Xcode project

**API Failures**: Use the "Test APIs" button to verify your keys are working

**Database Errors**: Check Supabase configuration and ensure the schema is set up correctly

**Navigation Issues**: The app uses NavigationStack for proper back button behavior

**Conversation Deletion**: You cannot delete the last conversation - create a new one first

### Error Messages

- "Failed to initialize chat": Check Supabase configuration
- "Model not found": Verify API keys and model availability
- "Authentication failed": Ensure anonymous auth is enabled in Supabase
- "Cannot delete last conversation": Create additional conversations before deleting

### Performance Tips

- **Groq API**: Fastest responses, use as primary provider
- **Mock AI**: Always available fallback when APIs fail
- **Conversation History**: Automatically managed and persisted
- **Memory Usage**: Messages are efficiently loaded per conversation