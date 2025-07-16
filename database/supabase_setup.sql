-- =================================================================
-- ChatBot AI - Supabase Database Setup
-- =================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =================================================================
-- ENUMS
-- =================================================================

-- Message types enum
CREATE TYPE message_type AS ENUM ('text', 'image', 'file', 'system');

-- Message status enum  
CREATE TYPE message_status AS ENUM ('sending', 'sent', 'delivered', 'failed');

-- =================================================================
-- TABLES
-- =================================================================

-- Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_from_user BOOLEAN NOT NULL DEFAULT true,
    message_type message_type DEFAULT 'text',
    status message_status DEFAULT 'sent',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================================================================
-- INDEXES
-- =================================================================

-- Index for faster conversation lookups by user
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);

-- Index for faster message lookups by conversation
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Composite index for conversation messages ordered by time
CREATE INDEX idx_messages_conversation_time ON messages(conversation_id, created_at DESC);

-- =================================================================
-- TRIGGERS
-- =================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for conversations
CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for messages
CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation updated_at when message is added
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET updated_at = NOW() 
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to update conversation when message is inserted
CREATE TRIGGER update_conversation_on_new_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_on_message();

-- =================================================================
-- ROW LEVEL SECURITY (RLS)
-- =================================================================

-- Enable RLS on tables
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policy for conversations - users can only access their own conversations
CREATE POLICY "Users can view own conversations" ON conversations
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own conversations" ON conversations
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own conversations" ON conversations
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own conversations" ON conversations
    FOR DELETE USING (auth.uid()::text = user_id);

-- Policy for messages - users can only access messages from their conversations
CREATE POLICY "Users can view messages from own conversations" ON messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can insert messages to own conversations" ON messages
    FOR INSERT WITH CHECK (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can update messages in own conversations" ON messages
    FOR UPDATE USING (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()::text
        )
    );

CREATE POLICY "Users can delete messages from own conversations" ON messages
    FOR DELETE USING (
        conversation_id IN (
            SELECT id FROM conversations WHERE user_id = auth.uid()::text
        )
    );

-- =================================================================
-- HELPER FUNCTIONS
-- =================================================================

-- Function to get conversation with message count
CREATE OR REPLACE FUNCTION get_conversation_with_stats(conversation_uuid UUID)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    title TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    message_count BIGINT,
    last_message_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.title,
        c.created_at,
        c.updated_at,
        COUNT(m.id) as message_count,
        MAX(m.created_at) as last_message_at
    FROM conversations c
    LEFT JOIN messages m ON c.id = m.conversation_id
    WHERE c.id = conversation_uuid
    GROUP BY c.id, c.user_id, c.title, c.created_at, c.updated_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent conversations for a user
CREATE OR REPLACE FUNCTION get_user_conversations(user_uuid TEXT, limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    user_id TEXT,
    title TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    message_count BIGINT,
    last_message TEXT,
    last_message_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.title,
        c.created_at,
        c.updated_at,
        COUNT(m.id) as message_count,
        (
            SELECT content 
            FROM messages m2 
            WHERE m2.conversation_id = c.id 
            ORDER BY m2.created_at DESC 
            LIMIT 1
        ) as last_message,
        MAX(m.created_at) as last_message_at
    FROM conversations c
    LEFT JOIN messages m ON c.id = m.conversation_id
    WHERE c.user_id = user_uuid
    GROUP BY c.id, c.user_id, c.title, c.created_at, c.updated_at
    ORDER BY COALESCE(MAX(m.created_at), c.created_at) DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- SAMPLE DATA (Optional - for testing)
-- =================================================================

-- Insert sample conversation
-- INSERT INTO conversations (id, user_id, title) 
-- VALUES (uuid_generate_v4(), 'sample-user-id', 'My First Chat');

-- Insert sample messages
-- INSERT INTO messages (conversation_id, content, is_from_user, message_type, status)
-- SELECT 
--     c.id,
--     'Hello! How can I help you today?',
--     false,
--     'text',
--     'sent'
-- FROM conversations c WHERE c.title = 'My First Chat';

-- =================================================================
-- GRANTS (if needed for service role)
-- =================================================================

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated; 