'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
    Send,
    Trash2,
    History,
    Plus,
    Sparkles,
    ShieldCheck,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import ReactMarkdown from 'react-markdown';
import { AIApi, AIMessage, AIConversation } from '@/services/api.client';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { HistorySidebar } from '@/components/tu-van/HistorySidebar';

type Message = AIMessage;

const QUICK_QUESTIONS = [
    'Dạo này tôi hay bị đau đầu khi chiều tối, lo không?',
    'Ngủ không ngon mấy hôm nay, có cách nào cải thiện không ạ?',
    'Phân tích sức khỏe của tôi dựa trên hồ sơ hiện tại nhé',
    'Các thuốc tôi đang dùng có ổn không bác sĩ?',
];

function formatTime(iso: string) {
    try {
        return new Date(iso).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    } catch { return ''; }
}

function MarkdownContent({ content }: { content: string }) {
    return (
        <ReactMarkdown
            components={{
                p: ({ children }) => <p style={{ margin: '2px 0 6px', lineHeight: 1.7 }}>{children}</p>,
                strong: ({ children }) => <strong style={{ fontWeight: 700, color: 'inherit' }}>{children}</strong>,
                em: ({ children }) => <em style={{ fontStyle: 'italic', opacity: 0.9 }}>{children}</em>,
                ul: ({ children }) => <ul style={{ margin: '8px 0 8px', paddingLeft: 22, listStyleType: 'disc' }}>{children}</ul>,
                ol: ({ children }) => <ol style={{ margin: '8px 0 8px', paddingLeft: 22 }}>{children}</ol>,
                li: ({ children }) => <li style={{ margin: '4px 0', lineHeight: 1.6 }}>{children}</li>,
                h1: ({ children }) => <h1 style={{ fontSize: 18, fontWeight: 800, margin: '16px 0 8px', color: 'var(--text-primary)' }}>{children}</h1>,
                h2: ({ children }) => <h2 style={{ fontSize: 16, fontWeight: 700, margin: '14px 0 6px', color: 'var(--text-primary)' }}>{children}</h2>,
                h3: ({ children }) => <h3 style={{ fontSize: 15, fontWeight: 600, margin: '12px 0 4px', opacity: 0.9 }}>{children}</h3>,
                hr: () => <hr style={{ border: 'none', borderTop: '1px solid rgba(0,0,0,0.06)', margin: '12px 0' }} />,
                blockquote: ({ children }) => (
                    <blockquote style={{ borderLeft: '4px solid var(--primary)', paddingLeft: 16, margin: '12px 0', opacity: 0.8, fontStyle: 'italic', background: 'rgba(20,184,166,0.04)', padding: '10px 16px', borderRadius: '0 12px 12px 0' }}>
                        {children}
                    </blockquote>
                ),
            }}
        >
            {content}
        </ReactMarkdown>
    );
}

// Typing animation — mượt mà và tự nhiên
function TypingBubble() {
    return (
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12 }}>
            <div style={{
                width: 38, height: 38, borderRadius: '14px',
                background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                fontSize: 14, fontWeight: 800, color: 'white',
                boxShadow: '0 4px 12px rgba(16,185,129,0.3)',
            }}>
                M
            </div>
            <div style={{
                padding: '14px 20px',
                background: 'var(--surface)',
                border: '1px solid var(--border)',
                borderRadius: '20px 20px 20px 6px',
                display: 'flex', alignItems: 'center', gap: 5,
                boxShadow: '0 4px 12px rgba(var(--primary-rgb), 0.03)',
            }}>
                {[0, 1, 2].map(i => (
                    <motion.span
                        key={i}
                        animate={{ opacity: [0.3, 1, 0.3], scale: [1, 1.2, 1] }}
                        transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.2 }}
                        style={{
                            width: 6, height: 6,
                            borderRadius: '50%',
                            background: 'var(--primary)',
                            display: 'block',
                        }}
                    />
                ))}
            </div>
        </div>
    );
}

export default function MediAIChatPage() {
    const [messages, setMessages] = useState<Message[]>([]);
    const [conversationId, setConversationId] = useState<string | null>(null);
    const [input, setInput] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isFetchingHistory, setIsFetchingHistory] = useState(true);
    const [showConfirm, setShowConfirm] = useState(false);
    const [showHistory, setShowHistory] = useState(false);
    const [isInputFocused, setIsInputFocused] = useState(false);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const messagesContainerRef = useRef<HTMLDivElement>(null);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    const scrollToBottom = (smooth = true) => {
        messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages, isLoading]);

    useEffect(() => {
        const loadInitialHistory = async () => {
            const savedPref = localStorage.getItem('medi_ai_chat_pref');
            try {
                if (savedPref === 'NEW') { setIsFetchingHistory(false); return; }
                const res = await AIApi.getConversations('CHAT');
                if (res.success && res.data && res.data.length > 0) {
                    let target = res.data.find((c: AIConversation) => c.id === savedPref && c.type === 'CHAT');
                    if (!target) target = res.data.find((c: AIConversation) => c.type === 'CHAT');
                    if (target) {
                        setConversationId(target.id);
                        await loadMessages(target.id);
                    }
                }
            } catch (err) {
                console.error('History fetch error:', err);
            } finally {
                setIsFetchingHistory(false);
            }
        };
        loadInitialHistory();
    }, []);

    const loadMessages = async (id: string) => {
        setIsFetchingHistory(true);
        try {
            const msgRes = await AIApi.getMessages(id);
            if (msgRes.success) {
                setMessages(msgRes.data || []);
                setTimeout(() => scrollToBottom(false), 50);
            }
        } catch (e) { console.error(e); }
        finally { setIsFetchingHistory(false); }
    };

    const handleSelectConversation = async (id: string) => {
        if (!id) { handleNewChat(); return; }
        if (id === conversationId) return;
        localStorage.setItem('medi_ai_chat_pref', id);
        setConversationId(id);
        setShowHistory(false);
        await loadMessages(id);
    };

    const handleNewChat = () => {
        localStorage.setItem('medi_ai_chat_pref', 'NEW');
        setConversationId(null);
        setMessages([]);
        setTimeout(() => textareaRef.current?.focus(), 150);
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        setInput(e.target.value);
        e.target.style.height = 'auto';
        e.target.style.height = Math.min(e.target.scrollHeight, 120) + 'px';
    };

    const handleSend = async (textOverride?: string) => {
        const text = (textOverride ?? input).trim();
        if (!text || isLoading) return;

        const tempId = Date.now().toString();
        setMessages(prev => [...prev, {
            id: tempId, role: 'USER', content: text,
            createdAt: new Date().toISOString(),
        }]);
        setInput('');
        if (textareaRef.current) textareaRef.current.style.height = 'auto';
        setIsLoading(true);

        try {
            const res = await AIApi.chat(text, conversationId || undefined);
            if (res.success && res.data) {
                const data = res.data;
                if (!conversationId) {
                    setConversationId(data.conversationId);
                    localStorage.setItem('medi_ai_chat_pref', data.conversationId);
                }
                setMessages(prev => [
                    ...prev.filter(m => m.id !== tempId),
                    { id: tempId, role: 'USER', content: text, createdAt: new Date().toISOString() },
                    {
                        id: data.message.id,
                        role: 'ASSISTANT',
                        content: data.message.content,
                        createdAt: data.message.createdAt,
                    },
                ]);
            } else throw new Error(res.message);
        } catch {
            setMessages(prev => [...prev, {
                id: Date.now().toString(), role: 'ASSISTANT',
                content: 'Xin lỗi bạn, hệ thống đang gặp chút sự cố kết nối. Hãy thử lại sau giây lát nhé 🙏',
                createdAt: new Date().toISOString(),
            }]);
        } finally {
            setIsLoading(false);
        }
    };

    const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend(); }
    };

    return (
        <div style={{
            display: 'flex', flexDirection: 'column',
            height: 'calc(100vh - 100px)',
            background: 'var(--background)',
            borderRadius: '36px', // INCREASED: For an ultra-rounded, premium feel as requested
            border: '1px solid var(--border)',
            overflow: 'hidden',
            boxShadow: '0 20px 60px -15px rgba(0,0,0,0.12)',
            position: 'relative',
        }}>

            {/* ──────── HEADER ──────── */}
            <header style={{
                padding: '16px 24px',
                background: 'var(--surface)',
                borderBottom: '1px solid var(--border)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                flexShrink: 0,
                zIndex: 10,
            }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                    <div style={{ position: 'relative' }}>
                        <motion.div
                            whileHover={{ scale: 1.05 }}
                            style={{
                                width: 48, height: 48, borderRadius: '16px',
                                background: 'linear-gradient(135deg, var(--primary), #0d9488)',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontSize: 20, fontWeight: 800, color: 'white',
                                boxShadow: '0 8px 20px -6px rgba(20,184,166,0.4)',
                                cursor: 'pointer',
                            }}
                        >
                            M
                        </motion.div>
                        <span style={{
                            position: 'absolute', bottom: -2, right: -2,
                            width: 14, height: 14,
                            background: '#22c55e',
                            borderRadius: '50%',
                            border: '3px solid var(--surface)',
                        }} />
                    </div>

                    <div>
                        <div style={{ fontWeight: 800, fontSize: 16, color: 'var(--text-primary)', letterSpacing: '-0.3px' }}>
                            Bác sĩ Medi
                        </div>
                        <div style={{ fontSize: 12, color: '#22c55e', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                            <motion.span
                                animate={{ opacity: [0.4, 1, 0.4] }}
                                transition={{ duration: 2, repeat: Infinity }}
                                style={{ width: 6, height: 6, background: '#22c55e', borderRadius: '50%' }}
                            />
                            Trực tuyến 24/7
                        </div>
                    </div>
                </div>

                <div style={{ display: 'flex', gap: 10 }}>
                    {[
                        { icon: <Plus size={20} />, title: 'Mới', fn: handleNewChat, color: 'var(--primary)' },
                        { icon: <History size={20} />, title: 'Lịch sử', fn: () => setShowHistory(true), color: 'var(--primary)' },
                        { icon: <Trash2 size={20} />, title: 'Xóa', fn: () => setShowConfirm(true), color: '#ef4444' },
                    ].map((btn, i) => (
                        <motion.button
                            key={i}
                            whileHover={{ y: -2, backgroundColor: 'var(--background)', borderColor: btn.color, color: btn.color }}
                            whileTap={{ scale: 0.95, y: 0 }}
                            onClick={btn.fn}
                            title={btn.title}
                            style={{
                                width: 42, height: 42,
                                borderRadius: '12px',
                                background: 'transparent',
                                border: '1.5px solid var(--border)',
                                color: 'var(--text-muted)',
                                cursor: 'pointer',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                transition: 'all 0.2s',
                            }}
                        >
                            {btn.icon}
                        </motion.button>
                    ))}
                </div>
            </header>

            {/* ──────── MESSAGES ──────── */}
            <div
                ref={messagesContainerRef}
                style={{
                    flex: 1,
                    overflowY: 'auto',
                    padding: '24px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 8,
                    scrollbarWidth: 'thin',
                    scrollbarColor: 'var(--border) transparent',
                    background: 'rgba(var(--primary-rgb), 0.01)',
                }}
            >
                <AnimatePresence>
                    {messages.length === 0 && !isLoading && !isFetchingHistory && (
                        <motion.div
                            initial={{ opacity: 0, y: 20 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.95 }}
                            style={{
                                display: 'flex', flexDirection: 'column',
                                alignItems: 'center',
                                margin: 'auto 0', // Changed to auto margin for safe vertical centering
                                gap: 32, padding: '40px 0',
                            }}
                        >
                            <div style={{ textAlign: 'center', maxWidth: 500 }}>
                                <motion.div
                                    animate={{
                                        y: [0, -10, 0],
                                        boxShadow: [
                                            '0 20px 40px -10px rgba(var(--primary-rgb),0.3)',
                                            '0 30px 60px -15px rgba(var(--primary-rgb),0.4)',
                                            '0 20px 40px -10px rgba(var(--primary-rgb),0.3)'
                                        ]
                                    }}
                                    transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
                                    style={{
                                        width: 100, height: 100, borderRadius: '32px',
                                        background: 'linear-gradient(135deg, var(--primary), #0d9488)',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        fontSize: 44, fontWeight: 900, color: 'white',
                                        margin: '0 auto 24px',
                                        userSelect: 'none',
                                    }}
                                >
                                    M
                                </motion.div>
                                <h2 style={{ fontSize: 28, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 12px', letterSpacing: '-0.8px' }}>
                                    Chào mừng bạn đến với Medi <Sparkles size={24} style={{ display: 'inline', color: '#fbbf24' }} />
                                </h2>
                                <p style={{ fontSize: 16, color: 'var(--text-secondary)', lineHeight: 1.6, margin: '0 auto' }}>
                                    Chào mừng bạn đến với MediChain. Mình là bác sĩ ảo hỗ trợ tư vấn sức khỏe 24/7 cho bạn.
                                </p>
                            </div>

                            <div style={{ display: 'flex', flexDirection: 'column', gap: 12, width: '100%', maxWidth: 480 }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                                    <div style={{ height: 1.5, flex: 1, background: 'linear-gradient(to right, transparent, var(--border))' }} />
                                    <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '1px' }}>Gợi ý cho bạn</span>
                                    <div style={{ height: 1.5, flex: 1, background: 'linear-gradient(to left, transparent, var(--border))' }} />
                                </div>
                                {QUICK_QUESTIONS.map((q, i) => (
                                    <motion.button
                                        key={i}
                                        whileHover={{ x: 8, backgroundColor: 'rgba(var(--primary-rgb),0.05)', borderColor: 'var(--primary)' }}
                                        whileTap={{ scale: 0.98 }}
                                        onClick={() => handleSend(q)}
                                        style={{
                                            padding: '14px 20px',
                                            background: 'var(--surface)',
                                            border: '1.5px solid var(--border)',
                                            borderRadius: '20px',
                                            color: 'var(--text-primary)',
                                            fontSize: 14.5,
                                            textAlign: 'left',
                                            cursor: 'pointer',
                                            display: 'flex', alignItems: 'center', gap: 12,
                                            transition: 'all 0.2s',
                                            boxShadow: '0 4px 6px -1px rgba(0,0,0,0.02)',
                                        }}
                                    >
                                        <div style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--primary)', opacity: 0.4 }} />
                                        {q}
                                    </motion.button>
                                ))}
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, opacity: 0.6, fontSize: 12, color: 'var(--text-muted)' }}>
                                <ShieldCheck size={14} />
                                Mọi thông tin trò chuyện đều được bảo mật 256-bit
                            </div>
                        </motion.div>
                    )}

                    {messages.map((msg, idx) => {
                        const isUser = msg.role === 'USER';
                        const prevMsg = messages[idx - 1];
                        const isSameRole = prevMsg?.role === msg.role;
                        const topGap = isSameRole ? 4 : 20;

                        return (
                            <motion.div
                                key={msg.id}
                                initial={{ opacity: 0, y: 15, scale: 0.98 }}
                                animate={{ opacity: 1, y: 0, scale: 1 }}
                                transition={{ duration: 0.3, ease: 'easeOut' }}
                                style={{
                                    display: 'flex',
                                    justifyContent: isUser ? 'flex-end' : 'flex-start',
                                    alignItems: 'flex-end',
                                    gap: 12,
                                    marginTop: topGap,
                                }}
                            >
                                {!isUser && (
                                    <div style={{
                                        width: 36, height: 36, borderRadius: '12px',
                                        background: isSameRole ? 'transparent' : 'linear-gradient(135deg, #10b981, #059669)',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                        fontSize: 13, fontWeight: 800, color: 'white',
                                        flexShrink: 0,
                                        visibility: isSameRole ? 'hidden' : 'visible',
                                        boxShadow: isSameRole ? 'none' : '0 4px 10px rgba(16,185,129,0.25)',
                                    }}>
                                        M
                                    </div>
                                )}

                                <div style={{
                                    maxWidth: '75%',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    alignItems: isUser ? 'flex-end' : 'flex-start',
                                }}>
                                    <div style={{
                                        padding: '12px 18px',
                                        borderRadius: isUser
                                            ? (isSameRole ? '22px 6px 22px 22px' : '22px 22px 6px 22px')
                                            : (isSameRole ? '6px 22px 22px 22px' : '22px 22px 22px 6px'),
                                        background: isUser ? 'var(--primary)' : 'var(--surface)',
                                        border: isUser ? 'none' : '1.5px solid var(--border)',
                                        color: isUser ? 'white' : 'var(--text-primary)',
                                        fontSize: '15px',
                                        lineHeight: 1.6,
                                        boxShadow: isUser
                                            ? '0 10px 15px -3px rgba(var(--primary-rgb),0.25)'
                                            : '0 4px 6px -1px rgba(0,0,0,0.03)',
                                        wordBreak: 'break-word',
                                        position: 'relative',
                                        overflow: 'hidden',
                                    }}>
                                        {isUser
                                            ? <span style={{ whiteSpace: 'pre-wrap' }}>{msg.content}</span>
                                            : <MarkdownContent content={msg.content} />
                                        }
                                    </div>

                                    {(idx === messages.length - 1 || messages[idx + 1]?.role !== msg.role) && (
                                        <motion.span
                                            initial={{ opacity: 0 }}
                                            animate={{ opacity: 0.5 }}
                                            style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 6, fontWeight: 500 }}
                                        >
                                            {formatTime(msg.createdAt)}
                                        </motion.span>
                                    )}
                                </div>
                            </motion.div>
                        );
                    })}
                </AnimatePresence>

                {isLoading && (
                    <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} style={{ marginTop: 20 }}>
                        <TypingBubble />
                    </motion.div>
                )}
            </div>

            {/* ──────── INPUT ──────── */}
            <div style={{
                padding: '16px 24px 24px',
                background: 'var(--surface)',
                borderTop: '1px solid var(--border)',
                flexShrink: 0,
            }}>
                <div style={{
                    display: 'flex',
                    alignItems: 'flex-end',
                    gap: 12,
                    padding: '10px 10px 10px 20px',
                    background: isInputFocused ? 'var(--surface)' : 'var(--background)',
                    borderRadius: '24px',
                    border: '1.5px solid',
                    borderColor: isInputFocused ? 'var(--primary)' : 'var(--border)',
                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                    boxShadow: isInputFocused ? '0 0 0 4px rgba(var(--primary-rgb), 0.1)' : 'inset 0 2px 4px rgba(0,0,0,0.02)',
                }}>
                    <textarea
                        ref={textareaRef}
                        rows={1}
                        value={input}
                        onChange={handleInputChange}
                        onKeyDown={handleKeyDown}
                        onFocus={() => setIsInputFocused(true)}
                        onBlur={() => setIsInputFocused(false)}
                        placeholder="Nhắn tin cho Medi..."
                        disabled={isLoading}
                        style={{
                            flex: 1,
                            background: 'transparent',
                            border: 'none',
                            outline: 'none',
                            color: 'var(--text-primary)',
                            fontSize: '15px',
                            lineHeight: 1.55,
                            resize: 'none',
                            margin: '6px 0',
                            maxHeight: 120,
                            fontFamily: 'inherit',
                        }}
                    />
                    <motion.button
                        whileHover={input.trim() ? { scale: 1.05 } : {}}
                        whileTap={input.trim() ? { scale: 0.95 } : {}}
                        onClick={() => handleSend()}
                        disabled={!input.trim() || isLoading}
                        style={{
                            width: 44, height: 44,
                            borderRadius: '16px',
                            background: (!input.trim() || isLoading) ? 'var(--border)' : 'var(--primary)',
                            color: 'white',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                            cursor: (!input.trim() || isLoading) ? 'not-allowed' : 'pointer',
                            flexShrink: 0,
                            transition: 'all 0.3s',
                            boxShadow: input.trim() ? '0 8px 16px -4px rgba(var(--primary-rgb),0.4)' : 'none',
                        }}
                    >
                        <Send size={18} strokeWidth={2.5} />
                    </motion.button>
                </div>

                <div style={{
                    display: 'flex', justifyContent: 'center', alignItems: 'center',
                    marginTop: 12, opacity: 0.5, fontSize: 11, color: 'var(--text-muted)', fontWeight: 500, gap: 12
                }}>
                    <span>Shift + Enter để xuống dòng</span>
                    <span style={{ width: 3, height: 3, background: 'currentColor', borderRadius: '50%' }} />
                    <span>Medi có thể trả lời chưa chính xác</span>
                </div>
            </div>

            {/* Modals */}
            <ConfirmModal
                isOpen={showConfirm}
                onClose={() => setShowConfirm(false)}
                onConfirm={() => { setShowConfirm(false); setConversationId(null); setMessages([]); localStorage.setItem('medi_ai_chat_pref', 'NEW'); }}
                title="Xóa lịch sử trò chuyện"
                message="Bạn có chắc chắn muốn xóa toàn bộ cuộc trò chuyện hiện tại? Hành động này không thể hoàn tác."
                confirmText="Xóa vĩnh viễn"
            />
            <HistorySidebar
                isOpen={showHistory}
                onClose={() => setShowHistory(false)}
                onSelectConversation={handleSelectConversation}
                currentConversationId={conversationId}
                onNewChat={handleNewChat}
            />
        </div>
    );
}
