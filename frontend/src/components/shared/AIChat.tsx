'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MessageCircle, X, Send, Bot, Loader2 } from 'lucide-react';

interface Message {
    id: string;
    role: string;
    content: string;
    createdAt: string;
}

export default function AIChat() {
    const [isOpen, setIsOpen] = useState(false);
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState('');
    const [loading, setLoading] = useState(false);
    const [conversationId, setConversationId] = useState<string | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    useEffect(() => {
        const handleOpenChat = () => setIsOpen(true);
        window.addEventListener('open-ai-chat', handleOpenChat);

        if (isOpen) {
            setTimeout(scrollToBottom, 100);
        }

        return () => window.removeEventListener('open-ai-chat', handleOpenChat);
    }, [messages, isOpen]);

    const handleSend = async (textOverride?: string) => {
        const textToSend = textOverride || input;
        if (!textToSend.trim() || loading) return;

        const userMessage = textToSend.trim();
        setInput('');

        const tempUserMessage: Message = {
            id: Date.now().toString(),
            role: 'USER',
            content: userMessage,
            createdAt: new Date().toISOString(),
        };
        setMessages(prev => [...prev, tempUserMessage]);
        setLoading(true);

        try {
            const token = localStorage.getItem('token');
            const response = await fetch('http://localhost:5000/api/ai/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`,
                },
                body: JSON.stringify({
                    message: userMessage,
                    conversationId,
                }),
            });

            const data = await response.json();
            if (!conversationId && data.conversationId) {
                setConversationId(data.conversationId);
            }
            setMessages(prev => [...prev, data.message]);
        } catch (error) {
            console.error('Error:', error);
            setMessages(prev => [...prev, {
                id: Date.now().toString(),
                role: 'ASSISTANT',
                content: 'Xin lỗi, đã có lỗi xảy ra. Hãy thử lại.',
                createdAt: new Date().toISOString(),
            }]);
        } finally {
            setLoading(false);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSend();
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <motion.div
                    initial={{ opacity: 0, y: 50, scale: 0.9 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 50, scale: 0.9 }}
                    style={{
                        position: 'fixed',
                        bottom: '80px',
                        right: '32px',
                        zIndex: 1000,
                        width: '420px',
                        maxWidth: 'calc(100vw - 64px)',
                        height: '600px',
                        maxHeight: 'calc(100vh - 120px)',
                        background: 'var(--surface)',
                        backdropFilter: 'blur(20px)',
                        border: '1px solid var(--border)',
                        borderRadius: '24px',
                        display: 'flex',
                        flexDirection: 'column',
                        boxShadow: 'var(--shadow-lg)',
                        overflow: 'hidden'
                    }}
                >
                    {/* Header */}
                    <div style={{
                        padding: '16px 20px',
                        background: 'var(--primary)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        color: 'white'
                    }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            <div style={{ background: 'rgba(255,255,255,0.2)', padding: '6px', borderRadius: '8px' }}>
                                <Bot size={20} />
                            </div>
                            <span style={{ fontWeight: 'bold' }}>Trợ lý MediChain AI</span>
                        </div>
                        <button onClick={() => setIsOpen(false)} style={{ color: 'white', opacity: 0.8, cursor: 'pointer' }}>
                            <X size={20} />
                        </button>
                    </div>

                    {/* Messages Container */}
                    <div style={{ flex: 1, overflowY: 'auto', padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        {messages.length === 0 ? (
                            <div style={{ textAlign: 'center', marginTop: '40px' }}>
                                <Bot size={48} color="var(--text-muted)" style={{ marginBottom: '16px', opacity: 0.2 }} />
                                <h3 style={{ color: 'var(--text-primary)', marginBottom: '8px' }}>Phòng chat AI</h3>
                                <p style={{ color: 'var(--text-secondary)', fontSize: '14px', marginBottom: '24px' }}>Tôi có thể giúp gì cho sức khỏe của bạn?</p>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', padding: '0 20px' }}>
                                    {['Tôi bị đau đầu, nên làm gì?', 'Phân tích sức khỏe của tôi'].map((q, i) => (
                                        <button
                                            key={i}
                                            onClick={() => handleSend(q)}
                                            style={{
                                                padding: '12px',
                                                background: 'var(--primary-light)',
                                                border: '1px solid var(--border)',
                                                borderRadius: '12px',
                                                color: 'var(--primary)',
                                                fontSize: '13px',
                                                textAlign: 'left',
                                                cursor: 'pointer',
                                                fontWeight: 500
                                            }}
                                        >
                                            {q}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        ) : (
                            messages.map(msg => (
                                <div key={msg.id} style={{ alignSelf: msg.role === 'USER' ? 'flex-end' : 'flex-start', maxWidth: '85%' }}>
                                    <div style={{
                                        padding: '12px 16px',
                                        borderRadius: '16px',
                                        background: msg.role === 'USER' ? 'var(--primary)' : 'var(--primary-light)',
                                        color: msg.role === 'USER' ? 'white' : 'var(--text-primary)',
                                        fontSize: '14px',
                                        lineHeight: '1.5',
                                        borderBottomRightRadius: msg.role === 'USER' ? '4px' : '16px',
                                        borderBottomLeftRadius: msg.role !== 'USER' ? '4px' : '16px',
                                        boxShadow: 'var(--shadow-sm)'
                                    }}>
                                        {msg.content}
                                    </div>
                                </div>
                            ))
                        )}
                        <div ref={messagesEndRef} />
                    </div>

                    {/* Input Area */}
                    <div style={{ padding: '20px', background: 'var(--background)', borderTop: '1px solid var(--border)' }}>
                        <div style={{ display: 'flex', gap: '8px', background: 'var(--surface)', padding: '8px 12px', borderRadius: '16px', border: '1px solid var(--border)' }}>
                            <input
                                value={input}
                                onChange={e => setInput(e.target.value)}
                                onKeyPress={handleKeyPress}
                                placeholder="Nhập tin nhắn..."
                                style={{ flex: 1, background: 'transparent', border: 'none', color: 'var(--text-primary)', outline: 'none', fontSize: '14px' }}
                            />
                            <button
                                onClick={() => handleSend()}
                                disabled={!input.trim() || loading}
                                style={{
                                    background: 'var(--primary)',
                                    border: 'none',
                                    color: 'white',
                                    width: '32px',
                                    height: '32px',
                                    borderRadius: '10px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    cursor: 'pointer',
                                    opacity: (!input.trim() || loading) ? 0.5 : 1
                                }}
                            >
                                {loading ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
                            </button>
                        </div>
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
