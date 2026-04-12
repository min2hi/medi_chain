'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Send, Loader2, Stethoscope, ShieldCheck, AlertCircle, PlusCircle } from 'lucide-react';
import { AIApi } from '@/services/api.client';
import ReactMarkdown from 'react-markdown';

interface Message {
    id: string;
    role: string;
    content: string;
    createdAt: string;
}

const SUGGESTED_QUESTIONS = [
    { icon: '🤒', text: 'Tôi bị đau đầu và sốt nhẹ, nên làm gì?' },
    { icon: '📊', text: 'Phân tích chỉ số sức khỏe của tôi' },
    { icon: '😴', text: 'Tôi hay mất ngủ, cách cải thiện?' },
    { icon: '💊', text: 'Thuốc tôi đang dùng có tương tác gì không?' },
];

function formatTime(iso: string) {
    try {
        return new Date(iso).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    } catch {
        return '';
    }
}

function TypingDots() {
    return (
        <div style={{ display: 'flex', gap: '5px', alignItems: 'center', padding: '4px 0' }}>
            {[0, 1, 2].map(i => (
                <span
                    key={i}
                    style={{
                        width: 8,
                        height: 8,
                        borderRadius: '50%',
                        background: 'var(--primary)',
                        display: 'inline-block',
                        animation: `bounce 1.2s ease-in-out ${i * 0.2}s infinite`,
                        opacity: 0.7,
                    }}
                />
            ))}
            <style>{`
                @keyframes bounce {
                    0%, 60%, 100% { transform: translateY(0); }
                    30% { transform: translateY(-6px); }
                }
            `}</style>
        </div>
    );
}

// Simple markdown renderer using dangerouslySetInnerHTML equivalent via ReactMarkdown
function MarkdownMessage({ content }: { content: string }) {
    return (
        <div className="ai-markdown-content">
            <ReactMarkdown
                components={{
                    p: ({ children }) => <p style={{ margin: '4px 0', lineHeight: 1.6 }}>{children}</p>,
                    strong: ({ children }) => <strong style={{ fontWeight: 700, color: 'inherit' }}>{children}</strong>,
                    em: ({ children }) => <em style={{ fontStyle: 'italic' }}>{children}</em>,
                    ul: ({ children }) => <ul style={{ margin: '6px 0', paddingLeft: 18 }}>{children}</ul>,
                    ol: ({ children }) => <ol style={{ margin: '6px 0', paddingLeft: 18 }}>{children}</ol>,
                    li: ({ children }) => <li style={{ margin: '3px 0', lineHeight: 1.5 }}>{children}</li>,
                    h1: ({ children }) => <h1 style={{ fontSize: 16, fontWeight: 700, margin: '10px 0 4px', color: 'var(--primary)' }}>{children}</h1>,
                    h2: ({ children }) => <h2 style={{ fontSize: 15, fontWeight: 700, margin: '8px 0 4px', color: 'var(--primary)' }}>{children}</h2>,
                    h3: ({ children }) => <h3 style={{ fontSize: 14, fontWeight: 600, margin: '6px 0 3px' }}>{children}</h3>,
                    hr: () => <hr style={{ border: 'none', borderTop: '1px solid rgba(255,255,255,0.15)', margin: '10px 0' }} />,
                    code: ({ children }) => <code style={{ background: 'rgba(0,0,0,0.15)', padding: '1px 5px', borderRadius: 4, fontSize: 12 }}>{children}</code>,
                }}
            >
                {content}
            </ReactMarkdown>
        </div>
    );
}

export default function AIChat() {
    const [isOpen, setIsOpen] = useState(false);
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState('');
    const [loading, setLoading] = useState(false);
    const [conversationId, setConversationId] = useState<string | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const inputRef = useRef<HTMLInputElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    // FIX #1 & #4: Tách event listener và loadHistory thành 2 useEffect riêng biệt
    // --- Effect 1: Quản lý event listener open-ai-chat ---
    useEffect(() => {
        const handleOpenChat = () => setIsOpen(true);
        window.addEventListener('open-ai-chat', handleOpenChat);
        return () => window.removeEventListener('open-ai-chat', handleOpenChat);
    }, []); // Chỉ chạy 1 lần lúc mount — không phụ thuộc isOpen

    // --- Effect 2: Load history đúng một lần lúc mount ---
    useEffect(() => {
        let isMounted = true; // Guard tránh setState sau unmount

        const loadHistory = async () => {
            try {
                const res = await AIApi.getConversations('CHAT');
                if (!isMounted) return; // Component đã unmount → bỏ qua
                if (res.success && res.data && res.data.length > 0) {
                    const latestChat = res.data[0];
                    if (latestChat) {
                        setConversationId(latestChat.id);
                        const msgRes = await AIApi.getMessages(latestChat.id);
                        if (!isMounted) return;
                        if (msgRes.success && msgRes.data) {
                            setMessages(msgRes.data.map((m: { id: string; role: string; content: string; createdAt: string }) => ({
                                id: m.id,
                                role: m.role,
                                content: m.content,
                                createdAt: m.createdAt,
                            })));
                        }
                    }
                }
            } catch (err) {
                console.error('[AIChat] Failed to load chat history:', err);
            }
        };

        loadHistory();

        return () => { isMounted = false; }; // Cleanup khi unmount
    }, []); // [] = chỉ chạy đúng 1 lần lúc mount

    // --- Effect 3: Scroll & focus khi chat mở ---
    useEffect(() => {
        if (isOpen) {
            setTimeout(scrollToBottom, 100);
            setTimeout(() => inputRef.current?.focus(), 300);
        }
    }, [isOpen]);

    useEffect(() => {
        if (messages.length > 0) scrollToBottom();
    }, [messages, loading]);

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
            const res = await AIApi.chat(userMessage, conversationId || undefined);

            if (res.success && res.data) {
                if (!conversationId) {
                    setConversationId(res.data.conversationId);
                }

                const aiMessage: Message = {
                    id: res.data.message.id,
                    role: 'ASSISTANT',
                    content: res.data.message.content,
                    createdAt: res.data.message.createdAt,
                };

                setMessages(prev => [...prev, aiMessage]);
            } else {
                // Smart error: dùng errorCode để hiển thị message phù hợp
                const errorCode = (res as any).errorCode;
                const friendlyMessage = (() => {
                    switch (errorCode) {
                        case 'NETWORK_ERROR':
                            return '📶 Không thể kết nối đến máy chủ. Vui lòng kiểm tra internet.';
                        case 'CLIENT_TIMEOUT':
                        case 'AI_TIMEOUT':
                            return '⏱️ AI đang xử lý quá lâu. Vui lòng thử lại.';
                        case 'AI_RATE_LIMITED':
                            return '⏳ Hệ thống đang bận. Vui lòng thử lại sau 30 giây.';
                        case 'AUTH_EXPIRED':
                            return '🔐 Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
                        default:
                            return res.message || '⚠️ Dịch vụ AI tạm gián đoạn. Vui lòng thử lại.';
                    }
                })();
                throw new Error(friendlyMessage);
            }
        } catch (error: unknown) {
            const message = error instanceof Error
                ? error.message
                : '⚠️ Dịch vụ AI tạm gián đoạn. Vui lòng thử lại.';
            console.error('[AIChat Widget] Error:', message);
            setMessages(prev => [...prev, {
                id: Date.now().toString(),
                role: 'ASSISTANT',
                content: message,
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

    const handleNewConversation = () => {
        setMessages([]);
        setConversationId(null);
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <motion.div
                    initial={{ opacity: 0, y: 60, scale: 0.92 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 60, scale: 0.92 }}
                    transition={{ type: 'spring', stiffness: 300, damping: 28 }}
                    style={{
                        position: 'fixed',
                        bottom: '88px',
                        right: '28px',
                        zIndex: 1000,
                        width: '440px',
                        maxWidth: 'calc(100vw - 48px)',
                        height: '640px',
                        maxHeight: 'calc(100vh - 110px)',
                        background: 'var(--surface)',
                        border: '1px solid var(--border)',
                        borderRadius: '24px',
                        display: 'flex',
                        flexDirection: 'column',
                        boxShadow: '0 24px 64px rgba(0,0,0,0.35), 0 0 0 1px rgba(255,255,255,0.05)',
                        overflow: 'hidden',
                    }}
                >
                    {/* ── Header ── */}
                    <div style={{
                        padding: '14px 18px',
                        background: 'linear-gradient(135deg, var(--primary) 0%, #0d8a6e 100%)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        color: 'white',
                        flexShrink: 0,
                    }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                            {/* Doctor avatar */}
                            <div style={{
                                width: 40, height: 40,
                                background: 'rgba(255,255,255,0.2)',
                                borderRadius: '50%',
                                border: '2px solid rgba(255,255,255,0.4)',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                position: 'relative',
                                flexShrink: 0,
                            }}>
                                <Stethoscope size={20} />
                                {/* Online dot */}
                                <span style={{
                                    position: 'absolute', bottom: 1, right: 1,
                                    width: 10, height: 10,
                                    background: '#4ade80',
                                    borderRadius: '50%',
                                    border: '2px solid white',
                                }} />
                            </div>
                            <div>
                                <div style={{ fontWeight: 700, fontSize: 15, letterSpacing: '-0.2px' }}>Dr. MediAI</div>
                                <div style={{ fontSize: 11, opacity: 0.85, display: 'flex', alignItems: 'center', gap: 4 }}>
                                    <span style={{ width: 6, height: 6, background: '#4ade80', borderRadius: '50%', display: 'inline-block' }} />
                                    Bác sĩ ảo · Trực tuyến 24/7
                                </div>
                            </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                            {/* New conversation button */}
                            <button
                                onClick={handleNewConversation}
                                title="Cuộc trò chuyện mới"
                                style={{
                                    background: 'rgba(255,255,255,0.15)',
                                    border: '1px solid rgba(255,255,255,0.25)',
                                    color: 'white',
                                    width: 32, height: 32,
                                    borderRadius: '10px',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    cursor: 'pointer',
                                    transition: 'background 0.2s',
                                }}
                                onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.25)')}
                                onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.15)')}
                            >
                                <PlusCircle size={16} />
                            </button>
                            <button
                                onClick={() => setIsOpen(false)}
                                style={{
                                    background: 'rgba(255,255,255,0.15)',
                                    border: '1px solid rgba(255,255,255,0.25)',
                                    color: 'white',
                                    width: 32, height: 32,
                                    borderRadius: '10px',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    cursor: 'pointer',
                                    transition: 'background 0.2s',
                                }}
                                onMouseEnter={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.25)')}
                                onMouseLeave={e => (e.currentTarget.style.background = 'rgba(255,255,255,0.15)')}
                            >
                                <X size={16} />
                            </button>
                        </div>
                    </div>

                    {/* ── Messages Container ── */}
                    <div style={{
                        flex: 1,
                        overflowY: 'auto',
                        padding: '16px',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '12px',
                        scrollbarWidth: 'thin',
                        scrollbarColor: 'var(--border) transparent',
                    }}>
                        {messages.length === 0 ? (
                            // Welcome screen
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 16, paddingTop: 8 }}>
                                {/* Greeting card */}
                                <div style={{
                                    background: 'linear-gradient(135deg, rgba(16,185,129,0.1) 0%, rgba(13,138,110,0.05) 100%)',
                                    border: '1px solid rgba(16,185,129,0.2)',
                                    borderRadius: 16,
                                    padding: '16px 18px',
                                    textAlign: 'center',
                                }}>
                                    <div style={{
                                        width: 56, height: 56,
                                        background: 'linear-gradient(135deg, var(--primary), #0d8a6e)',
                                        borderRadius: '50%',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        margin: '0 auto 12px',
                                        boxShadow: '0 4px 16px rgba(16,185,129,0.4)',
                                    }}>
                                        <Stethoscope size={28} color="white" />
                                    </div>
                                    <h3 style={{ color: 'var(--text-primary)', fontWeight: 700, fontSize: 16, margin: '0 0 6px' }}>
                                        Xin chào! Tôi là Dr. MediAI
                                    </h3>
                                    <p style={{ color: 'var(--text-secondary)', fontSize: 13, lineHeight: 1.6, margin: 0 }}>
                                        Bác sĩ ảo chuyên nghiệp của MediChain. Tôi có thể tư vấn sức khỏe, phân tích triệu chứng và hỗ trợ bạn 24/7.
                                    </p>
                                </div>

                                {/* Safety notice */}
                                <div style={{
                                    display: 'flex', gap: 8, alignItems: 'flex-start',
                                    background: 'rgba(245,158,11,0.08)',
                                    border: '1px solid rgba(245,158,11,0.2)',
                                    borderRadius: 12,
                                    padding: '10px 12px',
                                }}>
                                    <AlertCircle size={14} color="#f59e0b" style={{ flexShrink: 0, marginTop: 1 }} />
                                    <p style={{ fontSize: 11, color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
                                        Lời khuyên chỉ mang tính tham khảo. Không thay thế chẩn đoán y khoa chính thức.
                                    </p>
                                </div>

                                {/* Suggested questions */}
                                <div>
                                    <p style={{ fontSize: 12, color: 'var(--text-muted)', margin: '0 0 8px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                        Câu hỏi gợi ý
                                    </p>
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                                        {SUGGESTED_QUESTIONS.map((q, i) => (
                                            <button
                                                key={i}
                                                onClick={() => handleSend(q.text)}
                                                style={{
                                                    padding: '10px 14px',
                                                    background: 'var(--background)',
                                                    border: '1px solid var(--border)',
                                                    borderRadius: 12,
                                                    color: 'var(--text-primary)',
                                                    fontSize: 13,
                                                    textAlign: 'left',
                                                    cursor: 'pointer',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    gap: 10,
                                                    transition: 'all 0.2s',
                                                    fontWeight: 500,
                                                }}
                                                onMouseEnter={e => {
                                                    e.currentTarget.style.borderColor = 'var(--primary)';
                                                    e.currentTarget.style.background = 'rgba(16,185,129,0.06)';
                                                }}
                                                onMouseLeave={e => {
                                                    e.currentTarget.style.borderColor = 'var(--border)';
                                                    e.currentTarget.style.background = 'var(--background)';
                                                }}
                                            >
                                                <span style={{ fontSize: 16, flexShrink: 0 }}>{q.icon}</span>
                                                <span>{q.text}</span>
                                            </button>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        ) : (
                            // Message list
                            messages.map(msg => (
                                <div
                                    key={msg.id}
                                    style={{
                                        display: 'flex',
                                        flexDirection: 'column',
                                        alignItems: msg.role === 'USER' ? 'flex-end' : 'flex-start',
                                        gap: 4,
                                    }}
                                >
                                    {/* Role label */}
                                    {msg.role !== 'USER' && (
                                        <span style={{
                                            fontSize: 11,
                                            color: 'var(--primary)',
                                            fontWeight: 600,
                                            paddingLeft: 4,
                                            display: 'flex', alignItems: 'center', gap: 4,
                                        }}>
                                            <Stethoscope size={10} />
                                            Dr. MediAI
                                        </span>
                                    )}
                                    <div style={{
                                        maxWidth: '88%',
                                        padding: '10px 14px',
                                        borderRadius: msg.role === 'USER' ? '18px 18px 4px 18px' : '18px 18px 18px 4px',
                                        background: msg.role === 'USER'
                                            ? 'linear-gradient(135deg, var(--primary) 0%, #0d8a6e 100%)'
                                            : 'var(--background)',
                                        border: msg.role === 'USER' ? 'none' : '1px solid var(--border)',
                                        color: msg.role === 'USER' ? 'white' : 'var(--text-primary)',
                                        fontSize: 14,
                                        lineHeight: '1.6',
                                        boxShadow: msg.role === 'USER'
                                            ? '0 2px 12px rgba(16,185,129,0.25)'
                                            : 'var(--shadow-sm)',
                                    }}>
                                        {msg.role === 'USER'
                                            ? msg.content
                                            : <MarkdownMessage content={msg.content} />
                                        }
                                    </div>
                                    <span style={{ fontSize: 10, color: 'var(--text-muted)', paddingLeft: 4, paddingRight: 4 }}>
                                        {formatTime(msg.createdAt)}
                                    </span>
                                </div>
                            ))
                        )}

                        {/* Typing indicator */}
                        {loading && (
                            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 4 }}>
                                <span style={{ fontSize: 11, color: 'var(--primary)', fontWeight: 600, paddingLeft: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
                                    <Stethoscope size={10} />
                                    Dr. MediAI đang phân tích...
                                </span>
                                <div style={{
                                    padding: '10px 16px',
                                    borderRadius: '18px 18px 18px 4px',
                                    background: 'var(--background)',
                                    border: '1px solid var(--border)',
                                    boxShadow: 'var(--shadow-sm)',
                                }}>
                                    <TypingDots />
                                </div>
                            </div>
                        )}

                        <div ref={messagesEndRef} />
                    </div>

                    {/* ── Input Area ── */}
                    <div style={{
                        padding: '12px 14px 14px',
                        background: 'var(--background)',
                        borderTop: '1px solid var(--border)',
                        flexShrink: 0,
                    }}>
                        <div style={{
                            display: 'flex',
                            gap: '8px',
                            background: 'var(--surface)',
                            padding: '8px 10px 8px 14px',
                            borderRadius: '16px',
                            border: '1.5px solid var(--border)',
                            transition: 'border-color 0.2s',
                        }}
                            onFocusCapture={e => (e.currentTarget.style.borderColor = 'var(--primary)')}
                            onBlurCapture={e => (e.currentTarget.style.borderColor = 'var(--border)')}
                        >
                            <input
                                ref={inputRef}
                                value={input}
                                onChange={e => setInput(e.target.value)}
                                onKeyDown={handleKeyPress}
                                placeholder="Hỏi MediAI bất cứ điều gì về sức khỏe..."
                                disabled={loading}
                                style={{
                                    flex: 1,
                                    background: 'transparent',
                                    border: 'none',
                                    color: 'var(--text-primary)',
                                    outline: 'none',
                                    fontSize: 14,
                                    lineHeight: '1.4',
                                }}
                            />
                            <button
                                onClick={() => handleSend()}
                                disabled={!input.trim() || loading}
                                style={{
                                    background: (!input.trim() || loading) ? 'var(--border)' : 'linear-gradient(135deg, var(--primary), #0d8a6e)',
                                    border: 'none',
                                    color: 'white',
                                    width: 36,
                                    height: 36,
                                    borderRadius: '12px',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    cursor: (!input.trim() || loading) ? 'not-allowed' : 'pointer',
                                    flexShrink: 0,
                                    transition: 'all 0.2s',
                                    boxShadow: (!input.trim() || loading) ? 'none' : '0 2px 8px rgba(16,185,129,0.4)',
                                }}
                            >
                                {loading ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
                            </button>
                        </div>

                        {/* Disclaimer */}
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5, marginTop: 8 }}>
                            <ShieldCheck size={11} color="var(--text-muted)" />
                            <span style={{ fontSize: 10, color: 'var(--text-muted)' }}>
                                Lưu trữ bảo mật · Chatbot AI · MediChain
                            </span>
                        </div>
                    </div>
                </motion.div>
            )}
        </AnimatePresence>
    );
}
