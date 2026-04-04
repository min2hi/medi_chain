'use client';

import React, { useState, useEffect } from 'react';
import {
    X,
    MessageSquare,
    FileText,
    Search,
    Clock,
    Trash2,
    Calendar,
    ArrowRight,
    Plus,
    Clock3,
} from 'lucide-react';
import { motion, AnimatePresence, Variants } from 'framer-motion';
import { AIApi, AIConversation } from '@/services/api.client';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';

interface HistorySidebarProps {
    isOpen: boolean;
    onClose: () => void;
    onSelectConversation: (id: string) => void;
    currentConversationId: string | null;
    onNewChat: () => void;
}

// Sidebar variants for dead-smooth slide-in
const sidebarVariants: Variants = {
    closed: {
        x: '105%', // Slightly more to ensure shadow is hidden
        transition: {
            duration: 0.35,
            ease: [0.4, 0, 0.2, 1],
        },
    },
    open: {
        x: 0,
        transition: {
            type: 'spring',
            damping: 25,
            stiffness: 200,
        },
    },
};

const listContainerVariants: Variants = {
    closed: { opacity: 0 },
    open: {
        opacity: 1,
        transition: {
            staggerChildren: 0.05,
            delayChildren: 0.1,
        },
    },
};

const itemVariants: Variants = {
    closed: { opacity: 0, x: 20 },
    open: {
        opacity: 1,
        x: 0,
        transition: { duration: 0.3, ease: 'easeOut' }
    },
};

export function HistorySidebar({ isOpen, onClose, onSelectConversation, currentConversationId, onNewChat }: HistorySidebarProps) {
    const [activeTab, setActiveTab] = useState<'CHAT' | 'CONSULT'>('CHAT');
    const [conversations, setConversations] = useState<AIConversation[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        if (isOpen) {
            loadConversations();
        }
    }, [isOpen, activeTab]);

    const loadConversations = async () => {
        setIsLoading(true);
        try {
            const res = await AIApi.getConversations(activeTab);
            if (res.success && res.data) {
                const sorted = res.data.sort((a, b) =>
                    new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
                );
                setConversations(sorted);
            }
        } catch (error) {
            console.error("Failed to load history:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleDelete = async (e: React.MouseEvent, id: string) => {
        e.stopPropagation();
        if (!confirm('Bạn có muốn xóa cuộc trò chuyện này không?')) return;
        try {
            const res = await AIApi.deleteConversation(id);
            if (res.success) {
                setConversations(prev => prev.filter(c => c.id !== id));
                if (currentConversationId === id) {
                    onSelectConversation('');
                }
            }
        } catch (error) {
            console.error("Delete failed:", error);
        }
    };

    const filteredConversations = conversations.filter(c =>
        (c.title || '').toLowerCase().includes(searchQuery.toLowerCase())
    );

    const formatDate = (dateString: string) => {
        try {
            return formatDistanceToNow(new Date(dateString), { addSuffix: true, locale: vi });
        } catch (e) {
            return '';
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <>
                    {/* Backdrop */}
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        onClick={onClose}
                        style={{
                            position: 'absolute',
                            inset: 0,
                            background: 'rgba(15, 23, 42, 0.4)',
                            backdropFilter: 'blur(8px)',
                            zIndex: 45,
                        }}
                    />

                    {/* Sidebar */}
                    <motion.div
                        variants={sidebarVariants}
                        initial="closed"
                        animate="open"
                        exit="closed"
                        style={{
                            position: 'absolute',
                            top: '12px',
                            right: '12px',
                            bottom: '12px',
                            width: '400px',
                            maxWidth: '92%',
                            background: 'var(--surface)',
                            border: '1px solid var(--border)',
                            borderRadius: '32px',
                            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
                            zIndex: 50,
                            display: 'flex',
                            flexDirection: 'column',
                            overflow: 'hidden',
                            willChange: 'transform',
                        }}
                    >
                        {/* Header */}
                        <div style={{
                            padding: '24px 24px 16px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            background: 'rgba(20, 184, 166, 0.03)',
                        }}>
                            <div>
                                <h2 style={{ fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: 0, letterSpacing: '-0.5px' }}>
                                    Lịch sử hoạt động
                                </h2>
                                <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: '4px 0 0', fontWeight: 500 }}>
                                    Tra cứu các phiên tư vấn đã lưu
                                </p>
                            </div>
                            <motion.button
                                whileHover={{ scale: 1.1, rotate: 90 }}
                                whileTap={{ scale: 0.9 }}
                                onClick={onClose}
                                style={{
                                    width: 40, height: 40,
                                    borderRadius: '50%',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    background: 'var(--background)',
                                    border: '1px solid var(--border)',
                                    color: 'var(--text-muted)',
                                    cursor: 'pointer',
                                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)',
                                }}
                            >
                                <X size={20} />
                            </motion.button>
                        </div>

                        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '24px' }}>
                            {/* New Chat Button */}
                            <div style={{ marginBottom: '24px' }}>
                                <motion.button
                                    whileHover={{ y: -2, boxShadow: '0 12px 20px -5px rgba(20,184,166,0.3)' }}
                                    whileTap={{ scale: 0.98, y: 0 }}
                                    onClick={() => { onNewChat(); onClose(); }}
                                    style={{
                                        width: '100%',
                                        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
                                        padding: '16px',
                                        background: 'linear-gradient(135deg, var(--primary), #0d9488)',
                                        color: 'white',
                                        borderRadius: '20px',
                                        border: 'none',
                                        fontSize: 16, fontWeight: 700,
                                        cursor: 'pointer',
                                        transition: 'all 0.2s',
                                        boxShadow: '0 8px 15px -3px rgba(20,184,166,0.25)',
                                    }}
                                >
                                    <Plus size={20} strokeWidth={3} />
                                    Cuộc trò chuyện mới
                                </motion.button>
                            </div>

                            {/* Tabs */}
                            <div style={{ marginBottom: 20 }}>
                                <div style={{
                                    display: 'flex',
                                    background: 'var(--background)',
                                    padding: 6,
                                    borderRadius: '18px',
                                    border: '1.5px solid var(--border)',
                                    position: 'relative',
                                }}>
                                    <motion.div
                                        animate={{
                                            x: activeTab === 'CHAT' ? 0 : '100%',
                                        }}
                                        transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                                        style={{
                                            position: 'absolute',
                                            top: 6,
                                            bottom: 6,
                                            left: 6,
                                            width: 'calc(50% - 6px)',
                                            background: 'var(--primary)',
                                            borderRadius: '14px',
                                            boxShadow: '0 4px 12px rgba(20,184,166,0.25)',
                                        }}
                                    />
                                    {[
                                        { id: 'CHAT', label: 'Chatbot', icon: <MessageSquare size={17} /> },
                                        { id: 'CONSULT', label: 'Tư vấn Y khoa', icon: <FileText size={17} /> },
                                    ].map((tab) => (
                                        <button
                                            key={tab.id}
                                            onClick={() => setActiveTab(tab.id as 'CHAT' | 'CONSULT')}
                                            style={{
                                                flex: 1,
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                                                padding: '12px 0',
                                                borderRadius: '14px',
                                                border: 'none',
                                                zIndex: 1,
                                                fontSize: 14, fontWeight: 600,
                                                background: 'transparent',
                                                color: activeTab === tab.id ? 'white' : 'var(--text-muted)',
                                                cursor: 'pointer',
                                                transition: 'color 0.2s ease',
                                                position: 'relative',
                                            }}
                                        >
                                            {tab.icon}
                                            {tab.label}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Search */}
                            <div style={{ marginBottom: 20 }}>
                                <div style={{ position: 'relative' }}>
                                    <Search style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', opacity: 0.4 }} size={18} />
                                    <input
                                        type="text"
                                        value={searchQuery}
                                        onChange={(e) => setSearchQuery(e.target.value)}
                                        placeholder="Tìm kiếm nội dung..."
                                        style={{
                                            width: '100%',
                                            background: 'var(--background)',
                                            border: '1.5px solid var(--border)',
                                            borderRadius: '18px',
                                            padding: '14px 14px 14px 48px',
                                            fontSize: '14.5px',
                                            color: 'var(--text-primary)',
                                            outline: 'none',
                                            transition: 'all 0.2s',
                                        }}
                                        onFocus={(e) => {
                                            e.currentTarget.style.borderColor = 'var(--primary)';
                                            e.currentTarget.style.boxShadow = '0 0 0 4px rgba(20,184,166,0.1)';
                                        }}
                                        onBlur={(e) => {
                                            e.currentTarget.style.borderColor = 'var(--border)';
                                            e.currentTarget.style.boxShadow = 'none';
                                        }}
                                    />
                                </div>
                            </div>

                            {/* List with Staggered Animation */}
                            <div style={{
                                flex: 1,
                                overflowY: 'auto',
                                paddingRight: '4px',
                                display: 'flex',
                                flexDirection: 'column',
                                gap: 14,
                                scrollbarWidth: 'thin',
                                scrollbarColor: 'var(--border) transparent',
                            }}>
                                {isLoading ? (
                                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '60px 0', opacity: 0.5 }}>
                                        <Clock3 size={48} className="animate-spin" style={{ color: 'var(--primary)', opacity: 0.8 }} />
                                        <p style={{ marginTop: 16, fontSize: 14, fontWeight: 500 }}>Đang tải dữ liệu...</p>
                                    </div>
                                ) : filteredConversations.length > 0 ? (
                                    <motion.div
                                        variants={listContainerVariants}
                                        initial="closed"
                                        animate="open"
                                        style={{ display: 'flex', flexDirection: 'column', gap: 12 }}
                                    >
                                        {filteredConversations.map((item) => (
                                            <motion.div
                                                key={item.id}
                                                variants={itemVariants}
                                                onClick={() => onSelectConversation(item.id)}
                                                className="history-item-container"
                                                style={{ position: 'relative' }}
                                            >
                                                <div
                                                    className="history-item"
                                                    style={{
                                                        padding: '18px',
                                                        borderRadius: '24px',
                                                        border: '1.5px solid',
                                                        borderColor: currentConversationId === item.id ? 'var(--primary)' : 'var(--border)',
                                                        background: currentConversationId === item.id ? 'rgba(20, 184, 166, 0.04)' : 'var(--surface)',
                                                        cursor: 'pointer',
                                                        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                                        position: 'relative',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: 12,
                                                    }}
                                                >
                                                    <div style={{
                                                        width: 44, height: 44, borderRadius: '14px',
                                                        background: currentConversationId === item.id ? 'var(--primary)' : 'var(--background)',
                                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                        color: currentConversationId === item.id ? 'white' : 'var(--text-muted)',
                                                        flexShrink: 0,
                                                        transition: 'all 0.3s',
                                                    }}>
                                                        {activeTab === 'CHAT' ? <MessageSquare size={18} /> : <FileText size={18} />}
                                                    </div>

                                                    <div style={{ flex: 1, overflow: 'hidden' }}>
                                                        <h3 style={{
                                                            fontSize: 15, fontWeight: 700, margin: 0,
                                                            color: 'var(--text-primary)',
                                                            whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden',
                                                        }}>
                                                            {item.title || (activeTab === 'CHAT' ? 'Hỏi thăm sức khỏe' : 'Kết quả tư vấn')}
                                                        </h3>
                                                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4, opacity: 0.6 }}>
                                                            <Clock size={12} />
                                                            <span style={{ fontSize: 12, fontWeight: 500 }}>{formatDate(item.createdAt)}</span>
                                                        </div>
                                                    </div>

                                                    <ArrowRight size={16} style={{
                                                        opacity: 0.3,
                                                        transform: currentConversationId === item.id ? 'translateX(0)' : 'translateX(-4px)',
                                                        transition: 'all 0.3s'
                                                    }} />

                                                    <button
                                                        onClick={(e) => handleDelete(e, item.id)}
                                                        className="delete-item-btn"
                                                        style={{
                                                            position: 'absolute', top: -6, right: -6,
                                                            width: 30, height: 30, borderRadius: '50%',
                                                            background: '#fee2e2',
                                                            color: '#ef4444',
                                                            border: 'none',
                                                            cursor: 'pointer',
                                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                            opacity: 0,
                                                            transform: 'scale(0.8)',
                                                            transition: 'all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)',
                                                            boxShadow: '0 4px 12px rgba(239,68,68,0.2)',
                                                            zIndex: 10,
                                                        }}
                                                    >
                                                        <Trash2 size={14} />
                                                    </button>
                                                </div>
                                                <style>{`
                                                    .history-item-container:hover .delete-item-btn { opacity: 1; transform: scale(1); }
                                                    .history-item:hover { 
                                                        transform: translateY(-2px); 
                                                        border-color: var(--primary); 
                                                        background: var(--background);
                                                        box-shadow: 0 10px 20px -10px rgba(0,0,0,0.1);
                                                    }
                                                `}</style>
                                            </motion.div>
                                        ))}
                                    </motion.div>
                                ) : (
                                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '80px 0', opacity: 0.35 }}>
                                        <div style={{
                                            width: 80, height: 80, borderRadius: '30px',
                                            background: 'var(--background)',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            marginBottom: 20
                                        }}>
                                            <Calendar size={40} />
                                        </div>
                                        <p style={{ fontSize: 16, fontWeight: 600 }}>Chưa có nội dung</p>
                                        <p style={{ fontSize: 13, marginTop: 6 }}>Lịch sử sẽ xuất hiện sau phiên tư vấn</p>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Footer */}
                        <div style={{
                            padding: '20px 24px',
                            background: 'rgba(20, 184, 166, 0.03)',
                            borderTop: '1px solid var(--border)',
                            fontSize: 12, color: 'var(--text-muted)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                            fontWeight: 500,
                        }}>
                            <motion.span
                                animate={{ scale: [1, 1.2, 1] }}
                                transition={{ duration: 2, repeat: Infinity }}
                                style={{ width: 8, height: 8, borderRadius: '50%', background: '#10b981' }}
                            />
                            Dữ liệu của bạn được mã hóa an toàn
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
