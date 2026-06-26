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
import { AIApi, AIConversation, RecommendationSession, RecommendationApi } from '@/services/api.client';
import { formatDistanceToNow } from 'date-fns';
import { vi, enUS } from 'date-fns/locale';
import { useTranslation } from '@/i18n/I18nProvider';

interface HistorySidebarProps {
    isOpen: boolean;
    onClose: () => void;
    onSelectConversation: (id: string) => void;
    currentConversationId: string | null;
    onSelectSession?: (id: string) => void;
    currentSessionId?: string | null;
    onNewChat: () => void;
    initialTab?: 'CHAT' | 'CONSULT';
}

// Sidebar variants for dead-smooth slide-in
const sidebarVariants: Variants = {
    closed: {
        x: '105%',
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

export function HistorySidebar({
    isOpen,
    onClose,
    onSelectConversation,
    currentConversationId,
    onSelectSession,
    currentSessionId,
    onNewChat,
    initialTab = 'CHAT'
}: HistorySidebarProps) {
    const { t, locale } = useTranslation();
    const [activeTab, setActiveTab] = useState<'CHAT' | 'CONSULT'>(initialTab);
    const [conversations, setConversations] = useState<AIConversation[]>([]);
    const [sessions, setSessions] = useState<RecommendationSession[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        if (isOpen) {
            loadHistory();
        }
    }, [isOpen, activeTab]);

    useEffect(() => {
        if (isOpen && initialTab) {
            setActiveTab(initialTab);
        }
    }, [initialTab, isOpen]);

    const loadHistory = async () => {
        setIsLoading(true);
        try {
            if (activeTab === 'CHAT') {
                const res = await AIApi.getConversations('CHAT');
                if (res.success && res.data) {
                    const sorted = res.data.sort((a, b) =>
                        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
                    );
                    setConversations(sorted);
                }
            } else {
                const res = await RecommendationApi.getSessions(1, 30);
                if (res.success && res.data) {
                    setSessions(res.data.sessions || []);
                }
            }
        } catch (error) {
            console.error("Failed to load history:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleDelete = async (e: React.MouseEvent, id: string) => {
        e.stopPropagation();
        if (!confirm(t('ai_chat.delete_history_msg'))) return;
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

    const filteredSessions = sessions.filter(s =>
        (s.symptoms || '').toLowerCase().includes(searchQuery.toLowerCase())
    );

    const formatDate = (dateString: string) => {
        try {
            return formatDistanceToNow(new Date(dateString), { addSuffix: true, locale: locale === 'vi' ? vi : enUS });
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
                        className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm z-[45]"
                    />

                    {/* Sidebar */}
                    <motion.div
                        variants={sidebarVariants}
                        initial="closed"
                        animate="open"
                        exit="closed"
                        className="absolute top-3 right-3 bottom-3 w-[400px] max-w-[92%] bg-surface border border-border rounded-[32px] shadow-2xl z-50 flex flex-col overflow-hidden will-change-transform"
                    >
                        {/* Header */}
                        <div className="px-6 pt-6 pb-4 flex items-center justify-between bg-primary/[0.03]">
                            <div>
                                <h2 className="text-2xl font-extrabold text-primary m-0 tracking-tight">
                                    {t('ai_chat.sidebar_title')}
                                </h2>
                                <p className="text-xs text-muted mt-1 font-medium">
                                    {t('ai_chat.sidebar_empty_desc')}
                                </p>
                            </div>
                            <motion.button
                                whileHover={{ scale: 1.1, rotate: 90 }}
                                whileTap={{ scale: 0.9 }}
                                onClick={onClose}
                                className="w-10 h-10 rounded-full flex items-center justify-center bg-background border border-border text-muted cursor-pointer shadow-sm hover:text-primary transition-colors"
                            >
                                <X size={20} />
                            </motion.button>
                        </div>

                        <div className="flex-1 flex flex-col p-6">
                            {/* New Chat Button */}
                            <div className="mb-6">
                                <motion.button
                                    whileHover={{ y: -2, boxShadow: '0 12px 20px -5px rgba(20,184,166,0.3)' }}
                                    whileTap={{ scale: 0.98, y: 0 }}
                                    onClick={() => { onNewChat(); onClose(); }}
                                    className="w-full flex items-center justify-center gap-3 p-4 bg-gradient-to-br from-primary to-teal-600 text-white rounded-2xl border-none text-base font-bold cursor-pointer transition-all shadow-lg shadow-primary/25 hover:shadow-xl hover:shadow-primary/35"
                                >
                                    <Plus size={20} strokeWidth={3} />
                                    {t('ai_chat.sidebar_new')}
                                </motion.button>
                            </div>

                            {/* Tabs */}
                            <div className="mb-5">
                                <div className="flex bg-background p-1.5 rounded-2xl border border-border relative">
                                    <motion.div
                                        animate={{
                                            x: activeTab === 'CHAT' ? 0 : '100%',
                                        }}
                                        transition={{ type: 'spring', damping: 25, stiffness: 200 }}
                                        className="absolute top-1.5 bottom-1.5 left-1.5 w-[calc(50%-6px)] bg-primary rounded-xl shadow-md shadow-primary/25"
                                    />
                                    {[
                                        { id: 'CHAT', label: 'Chatbot', icon: <MessageSquare size={17} /> },
                                        { id: 'CONSULT', label: t('medications.consult'), icon: <FileText size={17} /> },
                                    ].map((tab) => (
                                        <button
                                            key={tab.id}
                                            onClick={() => setActiveTab(tab.id as 'CHAT' | 'CONSULT')}
                                            className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl border-none z-10 text-sm font-semibold bg-transparent cursor-pointer transition-colors relative ${activeTab === tab.id ? 'text-white' : 'text-muted hover:text-primary'}`}
                                        >
                                            {tab.icon}
                                            {tab.label}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Search */}
                            <div className="mb-5">
                                <div className="relative">
                                    <Search className="absolute left-4 top-1/2 -translate-y-1/2 opacity-40" size={18} />
                                    <input
                                        type="text"
                                        value={searchQuery}
                                        onChange={(e) => setSearchQuery(e.target.value)}
                                        placeholder="Tìm kiếm nội dung..."
                                        className="w-full bg-background border border-border rounded-2xl py-3.5 pl-12 pr-4 text-[14.5px] text-primary outline-none transition-all focus:border-primary focus:ring-4 focus:ring-primary/10"
                                    />
                                </div>
                            </div>

                            {/* List with Staggered Animation */}
                            <div className="flex-1 overflow-y-auto pr-1 flex flex-col gap-3.5 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent">
                                {isLoading ? (
                                    <div className="flex flex-col items-center py-15 opacity-50">
                                        <Clock3 size={48} className="animate-spin text-primary opacity-80" />
                                        <p className="mt-4 text-sm font-medium">Đang tải dữ liệu...</p>
                                    </div>
                                ) : activeTab === 'CHAT' ? (
                                    filteredConversations.length > 0 ? (
                                        <motion.div
                                            variants={listContainerVariants}
                                            initial="closed"
                                            animate="open"
                                            className="flex flex-col gap-3"
                                        >
                                            {filteredConversations.map((item) => (
                                                <motion.div
                                                    key={item.id}
                                                    variants={itemVariants}
                                                    onClick={() => { onSelectConversation(item.id); onClose(); }}
                                                    className="relative group"
                                                >
                                                    <div
                                                        className={`p-4.5 rounded-3xl border flex items-center gap-3 cursor-pointer relative transition-all duration-300 hover:-translate-y-0.5 hover:border-primary hover:bg-background hover:shadow-md ${currentConversationId === item.id ? 'border-primary bg-primary/5' : 'border-border bg-surface'}`}
                                                    >
                                                        <div className={`w-11 h-11 rounded-2xl flex items-center justify-center shrink-0 transition-all duration-300 ${currentConversationId === item.id ? 'bg-primary text-white' : 'bg-background text-muted'}`}>
                                                            <MessageSquare size={18} />
                                                        </div>

                                                        <div className="flex-1 overflow-hidden">
                                                            <h3 className="text-[15px] font-bold m-0 text-primary truncate">
                                                                {item.title || t('ai_chat.sidebar_today')}
                                                            </h3>
                                                            <div className="flex items-center gap-1.5 mt-1 opacity-60">
                                                                <Clock size={12} />
                                                                <span className="text-xs font-medium">{formatDate(item.createdAt)}</span>
                                                            </div>
                                                        </div>

                                                        <ArrowRight size={16} className={`opacity-30 transition-all duration-300 ${currentConversationId === item.id ? 'translate-x-0' : '-translate-x-1'}`} />

                                                        <button
                                                            onClick={(e) => handleDelete(e, item.id)}
                                                            className="absolute -top-1.5 -right-1.5 w-7.5 h-7.5 rounded-full bg-red-100 text-red-500 border-none cursor-pointer flex items-center justify-center opacity-0 scale-90 group-hover:opacity-100 group-hover:scale-100 transition-all duration-200 shadow-md shadow-red-500/10 z-10 hover:bg-red-200"
                                                        >
                                                            <Trash2 size={14} />
                                                        </button>
                                                    </div>
                                                </motion.div>
                                            ))}
                                        </motion.div>
                                    ) : (
                                        <div className="flex flex-col items-center py-20 opacity-35">
                                            <div className="w-20 h-20 rounded-[30px] bg-background flex items-center justify-center mb-5">
                                                <Calendar size={40} />
                                            </div>
                                            <p className="text-base font-semibold">{t('ai_chat.sidebar_empty')}</p>
                                            <p className="text-xs mt-1.5">{t('ai_chat.sidebar_empty_desc')}</p>
                                        </div>
                                    )
                                ) : (
                                    filteredSessions.length > 0 ? (
                                        <motion.div
                                            variants={listContainerVariants}
                                            initial="closed"
                                            animate="open"
                                            className="flex flex-col gap-3"
                                        >
                                            {filteredSessions.map((item) => (
                                                <motion.div
                                                    key={item.id}
                                                    variants={itemVariants}
                                                    onClick={() => { if (onSelectSession) onSelectSession(item.id); onClose(); }}
                                                    className="relative group"
                                                >
                                                    <div
                                                        className={`p-4.5 rounded-3xl border flex items-center gap-3 cursor-pointer relative transition-all duration-300 hover:-translate-y-0.5 hover:border-primary hover:bg-background hover:shadow-md ${currentSessionId === item.id ? 'border-primary bg-primary/5' : 'border-border bg-surface'}`}
                                                    >
                                                        <div className={`w-11 h-11 rounded-2xl flex items-center justify-center shrink-0 transition-all duration-300 ${currentSessionId === item.id ? 'bg-primary text-white' : 'bg-background text-muted'}`}>
                                                            <FileText size={18} />
                                                        </div>

                                                        <div className="flex-1 overflow-hidden">
                                                            <h3 className="text-[15px] font-bold m-0 text-primary truncate">
                                                                {item.symptoms}
                                                            </h3>
                                                            <div className="flex items-center gap-1.5 mt-1 opacity-60">
                                                                <Clock size={12} />
                                                                <span className="text-xs font-medium">{formatDate(item.createdAt)}</span>
                                                                {item.drugCount !== undefined && (
                                                                    <>
                                                                        <span className="w-0.5 h-0.5 bg-current rounded-full" />
                                                                        <span className="text-xs font-semibold text-primary">
                                                                            {item.drugCount} thuốc
                                                                        </span>
                                                                    </>
                                                                )}
                                                            </div>
                                                        </div>

                                                        <ArrowRight size={16} className={`opacity-30 transition-all duration-300 ${currentSessionId === item.id ? 'translate-x-0' : '-translate-x-1'}`} />
                                                    </div>
                                                </motion.div>
                                            ))}
                                        </motion.div>
                                    ) : (
                                        <div className="flex flex-col items-center py-20 opacity-35">
                                            <div className="w-20 h-20 rounded-[30px] bg-background flex items-center justify-center mb-5">
                                                <Calendar size={40} />
                                            </div>
                                            <p className="text-base font-semibold">Chưa có phiên tư vấn</p>
                                            <p className="text-xs mt-1.5">Hãy nhập triệu chứng để nhận tư vấn thuốc</p>
                                        </div>
                                    )
                                )}
                            </div>
                        </div>

                        {/* Footer */}
                        <div className="px-6 py-5 bg-primary/[0.03] border-t border-border text-xs text-muted flex items-center justify-center gap-2 font-medium">
                            <motion.span
                                animate={{ scale: [1, 1.2, 1] }}
                                transition={{ duration: 2, repeat: Infinity }}
                                className="w-2 h-2 rounded-full bg-emerald-500"
                            />
                            {t('ai_chat.secure_msg')}
                        </div>
                    </motion.div>
                </>
            )}
        </AnimatePresence>
    );
}
