# ChatBot AI

A modern iOS chat application built with SwiftUI that integrates multiple AI providers for intelligent conversations. Features real-time messaging, conversation management, and secure API key handling.

## Features

- **Multi-AI Provider Support**: Choose between Groq, Hugging Face, and Mock AI
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
  - Hugging Face (DialoGPT)
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
    
    // Get from: https://huggingface.co/settings/tokens  
    static let huggingFaceAPIKey = "hf_your_huggingface_token_here"
    
    // Get from: https://makersuite.google.com/app/apikey
    static let googleGeminiAPIKey = "your_gemini_api_key_here"
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
│   │   └── ChatModels.swift        # Data models
│   ├── Services/
│   │   ├── AIService.swift         # AI provider management
│   │   ├── SupabaseService.swift   # Database operations
│   │   └── AI Providers/
│   │       ├── GroqProvider.swift
│   │       └── HuggingFaceProvider.swift
│   └── Views/
│       ├── AIModelSelectorView.swift
│       ├── ChatInputView.swift
│       ├── ErrorBannerView.swift
│       └── TypingIndicatorView.swift
├── database/
│   └── supabase_setup.sql          # Database schema
└── SECURITY_SETUP.md               # Security configuration guide
```

## Usage

### Starting a Chat

1. Launch the app
2. The app will automatically sign in anonymously
3. Start typing in the input field at the bottom
4. Messages are automatically saved to your conversation history

### Switching AI Models

1. Tap the AI model selector in the top-right corner
2. Choose from available providers:
   - **Groq Llama**: Fast, high-quality responses
   - **Hugging Face**: Open-source models
   - **Mock AI**: For development and testing

### Testing API Connections

1. Tap "Test APIs" in the top-left corner
2. View the status of all configured providers
3. The app will auto-switch to working providers if others fail

## API Provider Setup

### Groq API
1. Visit [Groq Console](https://console.groq.com/keys)
2. Create an account and generate an API key
3. Free tier: 30 requests per minute

### Hugging Face
1. Visit [Hugging Face Settings](https://huggingface.co/settings/tokens)
2. Create a read token
3. Free tier with reasonable limits

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
- **ContentView**: Main chat interface with message list and input
- **ChatInputView**: Text input with keyboard management

### Adding New AI Providers

1. Create a new provider class conforming to `AIProviderProtocol`
2. Add the provider to `AIModel` enum
3. Update `AIService` to handle the new provider
4. Add configuration to `AIConfig`

## Security

- API keys are stored in a gitignored file (`APIKeys.swift`)
- Supabase handles secure authentication and data storage
- All API communications use HTTPS
- No sensitive data is hardcoded in the repository

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

**Keyboard Issues**: The app includes automatic keyboard dismissal on tap outside

### Error Messages

- "Failed to initialize chat": Check Supabase configuration
- "Model not found": Verify API keys and model availability
- "Authentication failed": Ensure anonymous auth is enabled in Supabase