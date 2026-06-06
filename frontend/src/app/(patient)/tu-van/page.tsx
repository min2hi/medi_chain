'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
    Send,
    Trash2,
    History,
    Plus,
    Sparkles,
    ShieldCheck,
    Pill,
    BrainCircuit,
    MessageSquare,
    RotateCcw,
    Activity,
    Info,
    ChevronDown,
    ChevronUp,
    Sliders,
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import ReactMarkdown from 'react-markdown';
import {
    AIApi,
    AIMessage,
    AIConversation,
    RecommendationResponse,
    RecommendationApi,
    RecommendationSession
} from '@/services/api.client';
import { ConfirmModal } from '@/components/shared/ConfirmModal';
import { HistorySidebar } from '@/components/tu-van/HistorySidebar';
import { ConsultResultPanel } from '@/components/tu-van/ConsultResultPanel';
import { QuickAddMedicineModal } from '@/components/tu-van/QuickAddMedicineModal';
import { useTranslation } from '@/i18n/I18nProvider';
import { dictionaries, Locale } from '@/i18n/dictionaries';

interface RawSessionItem {
    drugId: string;
    isRecommended: boolean;
    rank: number;
    finalScore: number;
    profileScore: number;
    safetyScore: number;
    historyScore: number;
    drug?: {
        name?: string;
        genericName?: string;
        ingredients?: string;
        category?: string;
        sideEffects?: string;
        viSummary?: string;
        indications?: string;
        viIndications?: string;
        viWarnings?: string;
    };
}

interface RawFeedbackItem {
    sideEffect?: string;
}

interface RawSessionDetail {
    id: string;
    conversationId?: string;
    aiExplanation?: string;
    createdAt: string;
    items?: RawSessionItem[];
    feedbacks?: RawFeedbackItem[];
    symptoms?: string;
    totalCandidates?: number;
    filteredOut?: number;
    finalRanked?: number;
    processingMs?: number;
}

type Message = AIMessage;
type Medicine = RecommendationResponse['recommendedMedicines'][0];

const getQuickQuestions = (t: (key: string) => string) => [
    t('ai_chat.quick_q1'),
    t('ai_chat.quick_q2'),
    t('ai_chat.quick_q3'),
    t('ai_chat.quick_q4'),
];

const getSymptomSuggestions = () => [
    'Tôi bị đau đầu kèm theo sốt nhẹ, đau nhức cơ thể từ tối qua.',
    'Bé nhà tôi 5 tuổi bị ho khan, ngứa họng và nghẹt mũi nhẹ.',
    'Tôi bị đau dạ dày âm ỉ sau khi ăn đồ cay nóng, kèm ợ chua.',
    'Tôi bị ngứa da, nổi mề đay đỏ sau khi ăn hải sản khoảng 2 giờ.'
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
                    <blockquote style={{
                        borderLeft: '4px solid var(--primary)',
                        paddingLeft: 16,
                        margin: '12px 0',
                        opacity: 0.8,
                        fontStyle: 'italic',
                        background: 'rgba(20,184,166,0.04)',
                        padding: '10px 16px',
                        borderRadius: '0 12px 12px 0'
                    }}>
                        {children}
                    </blockquote>
                ),
            }}
        >
            {content}
        </ReactMarkdown>
    );
}

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
    const { t, locale } = useTranslation();

    // UI tab state
    const [pageMode, setPageMode] = useState<'CHAT' | 'CONSULT'>('CHAT');

    // CHAT mode state
    const [messages, setMessages] = useState<Message[]>([]);
    const [conversationId, setConversationId] = useState<string | null>(null);
    const [chatInput, setChatInput] = useState('');
    const [isChatLoading, setIsChatLoading] = useState(false);

    // CONSULT mode state
    const [consultSymptoms, setConsultSymptoms] = useState('');
    const [consultResult, setConsultResult] = useState<RecommendationResponse | null>(null);
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [isConsultLoading, setIsConsultLoading] = useState(false);
    const [showHelper, setShowHelper] = useState(false);

    const appendHelperText = (text: string) => {
        setConsultSymptoms(prev => {
            const clean = prev.trim();
            if (!clean) return text;
            if (clean.endsWith('.') || clean.endsWith(',')) return `${clean} ${text}`;
            return `${clean}, ${text}`;
        });
    };

    // Global UI state
    const [isFetchingHistory, setIsFetchingHistory] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [showHistory, setShowHistory] = useState(false);
    const [isInputFocused, setIsInputFocused] = useState(false);

    // Cabinet Modal state
    const [selectedMed, setSelectedMed] = useState<Medicine | null>(null);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);

    const messagesEndRef = useRef<HTMLDivElement>(null);
    const messagesContainerRef = useRef<HTMLDivElement>(null);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    const scrollToBottom = (smooth = true) => {
        messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
    };

    useEffect(() => {
        if (pageMode === 'CHAT') {
            scrollToBottom();
        }
    }, [messages, isChatLoading, pageMode]);

    // Initial check to load recent chat history
    useEffect(() => {
        const loadInitialHistory = async () => {
            const savedPref = localStorage.getItem('medi_ai_chat_pref');
            try {
                if (savedPref === 'NEW') {
                    setIsFetchingHistory(false);
                    return;
                }
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
        } catch (e) {
            console.error(e);
        } finally {
            setIsFetchingHistory(false);
        }
    };

    const handleSelectConversation = async (id: string) => {
        setPageMode('CHAT');
        if (!id) {
            handleNewChat();
            return;
        }
        if (id === conversationId) return;
        localStorage.setItem('medi_ai_chat_pref', id);
        setConversationId(id);
        setShowHistory(false);
        await loadMessages(id);
    };

    const handleSelectSession = async (sId: string) => {
        setPageMode('CONSULT');
        setIsFetchingHistory(true);
        try {
            const res = await RecommendationApi.getSessionDetail(sId);
            if (res.success && res.data) {
                const sessionData = res.data as unknown as RawSessionDetail;
                // Map session detail to RecommendationResponse format
                const mappedResult: RecommendationResponse = {
                    sessionId: sessionData.id,
                    conversationId: sessionData.conversationId || '',
                    message: {
                        id: sessionData.id,
                        role: 'ASSISTANT',
                        content: sessionData.aiExplanation || '',
                        createdAt: sessionData.createdAt,
                    },
                    recommendedMedicines: (sessionData.items || [])
                        .filter((item: RawSessionItem) => item.isRecommended)
                        .map((item: RawSessionItem) => ({
                            drugId: item.drugId,
                            name: item.drug?.name || '',
                            genericName: item.drug?.genericName || '',
                            ingredients: item.drug?.ingredients || '',
                            category: item.drug?.category || '',
                            rank: item.rank,
                            finalScore: item.finalScore,
                            sideEffects: item.drug?.sideEffects || '',
                            scores: {
                                profile: item.profileScore / 100,
                                safety: item.safetyScore / 100,
                                history: item.historyScore / 100,
                                evidence: (item.finalScore - (item.profileScore + item.safetyScore + item.historyScore)/3)/100,
                            },
                            summary: item.drug?.viSummary || item.drug?.indications?.substring(0, 300) || '',
                            indications: item.drug?.viIndications || item.drug?.indications || '',
                            warnings: item.drug?.viWarnings || item.drug?.sideEffects || '',
                        })),
                    safetyWarnings: (sessionData.feedbacks || []).map((f: RawFeedbackItem) => f.sideEffect).filter((x): x is string => !!x),
                    engineStats: {
                        totalCandidates: sessionData.totalCandidates || 0,
                        filteredOut: sessionData.filteredOut || 0,
                        finalRanked: sessionData.finalRanked || 0,
                        processingMs: sessionData.processingMs || 0,
                    },
                    source: 'RECOMMENDATION_ENGINE'
                };
                setConsultResult(mappedResult);
                setSessionId(sessionData.id);
                setConsultSymptoms(sessionData.symptoms || '');
                setShowHistory(false);
            }
        } catch (e) {
            console.error('Failed to load session detail:', e);
        } finally {
            setIsFetchingHistory(false);
        }
    };

    const handleNewChat = () => {
        localStorage.setItem('medi_ai_chat_pref', 'NEW');
        setConversationId(null);
        setMessages([]);
        setTimeout(() => textareaRef.current?.focus(), 150);
    };

    const handleNewConsult = () => {
        setConsultResult(null);
        setSessionId(null);
        setConsultSymptoms('');
    };

    const handleSend = async (textOverride?: string) => {
        const text = (textOverride ?? chatInput).trim();
        if (!text || isChatLoading) return;

        const tempId = Date.now().toString();
        setMessages(prev => [...prev, {
            id: tempId,
            role: 'USER',
            content: text,
            createdAt: new Date().toISOString(),
        }]);
        setChatInput('');
        if (textareaRef.current) textareaRef.current.style.height = 'auto';
        setIsChatLoading(true);

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
            } else {
                const errorCode = res.errorCode;
                const aiDict = dictionaries[locale as Locale].ai_chat;
                const friendlyMessage = (() => {
                    switch (errorCode) {
                        case 'NETWORK_ERROR': return aiDict.err_network;
                        case 'CLIENT_TIMEOUT': return aiDict.err_timeout;
                        case 'AI_RATE_LIMITED': return aiDict.err_busy;
                        case 'AUTH_EXPIRED': return aiDict.err_auth;
                        case 'CONVERSATION_NOT_FOUND':
                            setConversationId(null);
                            localStorage.removeItem('medi_ai_chat_pref');
                            return aiDict.err_not_found;
                        default: return aiDict.err_default;
                    }
                })();
                throw new Error(friendlyMessage);
            }
        } catch (err: unknown) {
            const aiDict = dictionaries[locale as Locale].ai_chat;
            const msg = err instanceof Error ? err.message : aiDict.err_default;
            setMessages(prev => [...prev, {
                id: Date.now().toString(),
                role: 'ASSISTANT',
                content: msg,
                createdAt: new Date().toISOString(),
            }]);
        } finally {
            setIsChatLoading(false);
        }
    };

    const handleConsultSubmit = async (symptomsText?: string) => {
        const query = (symptomsText ?? consultSymptoms).trim();
        if (!query || isConsultLoading) return;

        setConsultSymptoms(query);
        setIsConsultLoading(true);
        setConsultResult(null);

        try {
            const res = await AIApi.consult(query);
            if (res.success && res.data) {
                setConsultResult(res.data);
                setSessionId(res.data.sessionId);
            } else {
                // If safety triggers or validation errors occur, render them in response
                throw new Error(res.message || 'Không thể lấy kết quả tư vấn y tế. Vui lòng thử lại.');
            }
        } catch (err) {
            const errMsg = err instanceof Error ? err.message : 'Lỗi hệ thống khi kết nối đến AI engine.';
            alert(errMsg);
        } finally {
            setIsConsultLoading(false);
        }
    };

    const handleAddMedicineClick = (med: Medicine) => {
        setSelectedMed(med);
        setIsAddModalOpen(true);
    };

    const handleCabinetSuccess = (medName: string) => {
        // Soft toast or notify user of addition
        alert(`Đã thêm thành công ${medName} vào Cabinet!`);
    };

    return (
        <div style={{
            display: 'flex',
            flexDirection: 'column',
            height: 'calc(100vh - 100px)',
            background: 'var(--background)',
            borderRadius: '36px',
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
                            Tư vấn sức khỏe AI
                        </div>
                        <div style={{ fontSize: 12, color: '#22c55e', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>
                            <motion.span
                                animate={{ opacity: [0.4, 1, 0.4] }}
                                transition={{ duration: 2, repeat: Infinity }}
                                style={{ width: 6, height: 6, background: '#22c55e', borderRadius: '50%' }}
                            />
                            Hệ thống hoạt động ổn định
                        </div>
                    </div>
                </div>

                {/* Segmented Tab Switcher */}
                <div style={{
                    display: 'flex',
                    background: 'var(--background)',
                    border: '1.5px solid var(--border)',
                    padding: 3,
                    borderRadius: 14,
                    alignItems: 'center',
                    gap: 4
                }}>
                    <button
                        onClick={() => setPageMode('CHAT')}
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '8px 16px',
                            borderRadius: 10,
                            fontSize: 13,
                            fontWeight: 700,
                            border: 'none',
                            cursor: 'pointer',
                            background: pageMode === 'CHAT' ? 'var(--surface)' : 'transparent',
                            color: pageMode === 'CHAT' ? 'var(--primary)' : 'var(--text-secondary)',
                            boxShadow: pageMode === 'CHAT' ? '0 4px 12px rgba(0,0,0,0.05)' : 'none',
                            transition: 'all 0.2s',
                        }}
                    >
                        <MessageSquare size={14} />
                        Trò chuyện AI
                    </button>
                    <button
                        onClick={() => setPageMode('CONSULT')}
                        style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 6,
                            padding: '8px 16px',
                            borderRadius: 10,
                            fontSize: 13,
                            fontWeight: 700,
                            border: 'none',
                            cursor: 'pointer',
                            background: pageMode === 'CONSULT' ? 'var(--surface)' : 'transparent',
                            color: pageMode === 'CONSULT' ? 'var(--primary)' : 'var(--text-secondary)',
                            boxShadow: pageMode === 'CONSULT' ? '0 4px 12px rgba(0,0,0,0.05)' : 'none',
                            transition: 'all 0.2s',
                        }}
                    >
                        <BrainCircuit size={14} />
                        Tư vấn thuốc
                    </button>
                </div>

                <div style={{ display: 'flex', gap: 10 }}>
                    <motion.button
                        whileHover={{ y: -2, backgroundColor: 'var(--background)', color: 'var(--primary)' }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => pageMode === 'CHAT' ? handleNewChat() : handleNewConsult()}
                        title="Tạo mới"
                        style={{
                            width: 42, height: 42,
                            borderRadius: '12px',
                            background: 'transparent',
                            border: '1.5px solid var(--border)',
                            color: 'var(--text-muted)',
                            cursor: 'pointer',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}
                    >
                        <Plus size={20} />
                    </motion.button>
                    <motion.button
                        whileHover={{ y: -2, backgroundColor: 'var(--background)', color: 'var(--primary)' }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setShowHistory(true)}
                        title="Lịch sử"
                        style={{
                            width: 42, height: 42,
                            borderRadius: '12px',
                            background: 'transparent',
                            border: '1.5px solid var(--border)',
                            color: 'var(--text-muted)',
                            cursor: 'pointer',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}
                    >
                        <History size={20} />
                    </motion.button>
                    {pageMode === 'CHAT' && (
                        <motion.button
                            whileHover={{ y: -2, backgroundColor: 'var(--background)', color: '#ef4444' }}
                            whileTap={{ scale: 0.95 }}
                            onClick={() => setShowConfirm(true)}
                            title="Xóa lịch sử chat"
                            style={{
                                width: 42, height: 42,
                                borderRadius: '12px',
                                background: 'transparent',
                                border: '1.5px solid var(--border)',
                                color: 'var(--text-muted)',
                                cursor: 'pointer',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                            }}
                        >
                            <Trash2 size={20} />
                        </motion.button>
                    )}
                </div>
            </header>

            {/* ──────── MAIN AREA ──────── */}
            <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
                <AnimatePresence mode="wait">
                    {pageMode === 'CHAT' ? (
                        <motion.div
                            key="chat-tab"
                            initial={{ opacity: 0, x: -15 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: 15 }}
                            transition={{ duration: 0.25 }}
                            style={{ display: 'flex', flexDirection: 'column', flex: 1, height: '100%' }}
                        >
                            {/* MESSAGES */}
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
                                    background: 'rgba(20, 184, 166, 0.01)',
                                }}
                            >
                                {messages.length === 0 && !isChatLoading && !isFetchingHistory && (
                                    <div style={{
                                        display: 'flex', flexDirection: 'column',
                                        alignItems: 'center', margin: '40px auto 20px', gap: 20, padding: '20px 0',
                                    }}>
                                        <div style={{ textAlign: 'center', maxWidth: 500 }}>
                                            <motion.div
                                                animate={{ y: [0, -10, 0] }}
                                                transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
                                                style={{
                                                    width: 80, height: 80, borderRadius: '24px',
                                                    background: 'linear-gradient(135deg, var(--primary), #0d9488)',
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    fontSize: 32, fontWeight: 900, color: 'white',
                                                    margin: '0 auto 16px',
                                                    userSelect: 'none',
                                                }}
                                            >
                                                M
                                            </motion.div>
                                            <h2 style={{ fontSize: 24, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 8px', letterSpacing: '-0.8px' }}>
                                                {t('ai_chat.welcome_title')} <Sparkles size={20} style={{ display: 'inline', color: '#fbbf24' }} />
                                            </h2>
                                            <p style={{ fontSize: 14.5, color: 'var(--text-secondary)', lineHeight: 1.5, margin: '0 auto' }}>
                                                {t('ai_chat.welcome_desc')}
                                            </p>
                                        </div>

                                    </div>
                                )}

                                {messages.map((msg, idx) => {
                                    const isUser = msg.role === 'USER';
                                    const prevMsg = messages[idx - 1];
                                    const isSameRole = prevMsg?.role === msg.role;
                                    const topGap = isSameRole ? 4 : 20;

                                    return (
                                        <div
                                            key={msg.id}
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
                                                        ? '0 10px 15px -3px rgba(20,184,166,0.15)'
                                                        : '0 4px 6px -1px rgba(0,0,0,0.03)',
                                                    wordBreak: 'break-word',
                                                }}>
                                                    {isUser
                                                        ? <span style={{ whiteSpace: 'pre-wrap' }}>{msg.content}</span>
                                                        : <MarkdownContent content={msg.content} />
                                                    }
                                                </div>
                                                {(idx === messages.length - 1 || messages[idx + 1]?.role !== msg.role) && (
                                                    <span style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 6, fontWeight: 500 }}>
                                                        {formatTime(msg.createdAt)}
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}

                                {isFetchingHistory && (
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: 16, padding: '8px 0' }}>
                                        {[1, 2, 3].map(i => (
                                            <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'flex-end' }}>
                                                <div style={{ width: 36, height: 36, borderRadius: 12, background: 'var(--border)', flexShrink: 0 }} />
                                                <div style={{ height: 56, borderRadius: 16, background: 'var(--border)', flex: 1, opacity: 0.6 - i * 0.15 }} />
                                            </div>
                                        ))}
                                    </div>
                                )}

                                {isChatLoading && (
                                    <div style={{ marginTop: 20 }}>
                                        <TypingBubble />
                                    </div>
                                )}
                                <div ref={messagesEndRef} />
                            </div>

                            {/* CHAT INPUT AREA */}
                            <div style={{
                                padding: '12px 20px 20px',
                                background: 'var(--surface)',
                                borderTop: '1px solid var(--border)',
                                flexShrink: 0,
                            }}>
                                <div style={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: 10,
                                    padding: '6px 6px 6px 16px',
                                    background: isInputFocused ? 'var(--surface)' : 'var(--background)',
                                    borderRadius: '18px',
                                    border: '1.5px solid',
                                    borderColor: isInputFocused ? 'var(--primary)' : 'var(--border)',
                                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                }}>
                                    <textarea
                                        ref={textareaRef}
                                        rows={1}
                                        value={chatInput}
                                        onChange={(e) => {
                                            setChatInput(e.target.value);
                                            e.target.style.height = 'auto';
                                            e.target.style.height = Math.min(e.target.scrollHeight, 100) + 'px';
                                        }}
                                        onKeyDown={(e) => {
                                            if (e.key === 'Enter' && !e.shiftKey) {
                                                e.preventDefault();
                                                handleSend();
                                            }
                                        }}
                                        onFocus={() => setIsInputFocused(true)}
                                        onBlur={() => setIsInputFocused(false)}
                                        placeholder={t('ai_chat.input_ph')}
                                        disabled={isChatLoading}
                                        style={{
                                            flex: 1,
                                            background: 'transparent',
                                            border: 'none',
                                            outline: 'none',
                                            color: 'var(--text-primary)',
                                            fontSize: '14px',
                                            lineHeight: 1.5,
                                            resize: 'none',
                                            margin: '4px 0',
                                            maxHeight: 100,
                                            fontFamily: 'inherit',
                                        }}
                                    />
                                    <motion.button
                                        whileHover={chatInput.trim() ? { scale: 1.05 } : {}}
                                        whileTap={chatInput.trim() ? { scale: 0.95 } : {}}
                                        onClick={() => handleSend()}
                                        disabled={!chatInput.trim() || isChatLoading}
                                        style={{
                                            width: 36, height: 36,
                                            borderRadius: '12px',
                                            background: (!chatInput.trim() || isChatLoading) ? 'var(--border)' : 'var(--primary)',
                                            color: 'white',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                                            cursor: (!chatInput.trim() || isChatLoading) ? 'not-allowed' : 'pointer',
                                            flexShrink: 0,
                                            transition: 'all 0.3s',
                                        }}
                                    >
                                        <Send size={15} strokeWidth={2.5} />
                                    </motion.button>
                                </div>

                                <div style={{
                                    display: 'flex', justifyContent: 'center', alignItems: 'center',
                                    marginTop: 12, opacity: 0.5, fontSize: 11, color: 'var(--text-muted)', fontWeight: 500, gap: 12
                                }}>
                                    <span>{t('ai_chat.hint_newline')}</span>
                                    <span style={{ width: 3, height: 3, background: 'currentColor', borderRadius: '50%' }} />
                                    <span>{t('ai_chat.hint_disclaimer')}</span>
                                </div>
                            </div>
                        </motion.div>
                    ) : (
                        <motion.div
                            key="consult-tab"
                            initial={{ opacity: 0, x: 15 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -15 }}
                            transition={{ duration: 0.25 }}
                            style={{
                                display: 'flex',
                                flex: 1,
                                height: '100%',
                                overflow: 'hidden',
                                background: 'var(--background)'
                            }}
                        >
                            {/* Left Side: Result Details (If exists) / Description Guide */}
                            <div style={{
                                flex: 1,
                                display: 'flex',
                                flexDirection: 'column',
                                height: '100%',
                                overflow: 'hidden',
                                borderRight: consultResult ? '1px solid var(--border)' : 'none',
                            }}>
                                {/* Scrollable content body */}
                                <div style={{
                                    flex: 1,
                                    overflowY: 'auto',
                                    padding: '24px',
                                    display: 'flex',
                                    flexDirection: 'column',
                                    scrollbarWidth: 'thin',
                                    scrollbarColor: 'var(--border) transparent',
                                }}>
                                    {consultResult ? (
                                        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                                            {/* Symptoms Summary */}
                                            <div style={{
                                                background: 'var(--surface)',
                                                border: '1.5px solid var(--border)',
                                                borderRadius: 20,
                                                padding: 16,
                                                position: 'relative'
                                            }}>
                                                <span style={{
                                                    position: 'absolute', top: -10, left: 16,
                                                    fontSize: 11, fontWeight: 700, background: 'var(--background)',
                                                    padding: '0 8px', color: 'var(--primary)'
                                                }}>
                                                    MÔ TẢ TRIỆU CHỨNG CỦA BẠN
                                                </span>
                                                <p style={{
                                                    fontSize: 14, fontWeight: 600, color: 'var(--text-primary)',
                                                    margin: 0, lineHeight: 1.6
                                                }}>
                                                    {consultSymptoms}
                                                </p>
                                            </div>

                                            {/* AI Diagnosis explanation */}
                                            {consultResult.message?.content && (
                                                <div style={{
                                                    background: 'var(--surface)',
                                                    border: '1.5px solid var(--border)',
                                                    borderRadius: 20,
                                                    padding: 20,
                                                }}>
                                                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                                                        <Sparkles size={16} style={{ color: 'var(--primary)' }} />
                                                        <h3 style={{ fontSize: 15, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                                                            Phân tích y tế & Giải thích thuốc
                                                        </h3>
                                                    </div>
                                                    <div style={{ fontSize: 13.5, color: 'var(--text-secondary)', lineHeight: 1.65 }}>
                                                        <MarkdownContent content={consultResult.message.content} />
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ) : (
                                        <div style={{
                                            display: 'flex', flexDirection: 'column',
                                            alignItems: 'center', margin: '40px auto 20px', gap: 20, padding: '20px 0'
                                        }}>
                                            <div style={{ textAlign: 'center', maxWidth: 520 }}>
                                                <motion.div
                                                    animate={{
                                                        scale: [1, 1.05, 1],
                                                        rotate: [0, 5, -5, 0]
                                                    }}
                                                    transition={{ duration: 5, repeat: Infinity }}
                                                    style={{
                                                        width: 80, height: 80, borderRadius: '24px',
                                                        background: 'linear-gradient(135deg, #6366f1, #4f46e5)',
                                                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                        margin: '0 auto 16px',
                                                        boxShadow: '0 12px 30px rgba(99,102,241,0.25)'
                                                    }}
                                                >
                                                    <BrainCircuit size={36} style={{ color: 'white' }} />
                                                </motion.div>
                                                <h2 style={{ fontSize: 22, fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 8px' }}>
                                                    Tư vấn & Gợi ý thuốc AI
                                                </h2>
                                                <p style={{ fontSize: 14, color: 'var(--text-secondary)', lineHeight: 1.5, margin: 0 }}>
                                                    Mô tả các triệu chứng của bạn thật chi tiết (bao gồm thời gian, mức độ, tiền sử bệnh nền). Recommendation Engine sẽ phân tích và đưa ra giải pháp an toàn nhất.
                                                </p>
                                            </div>

                                        </div>
                                    )}
                                </div>

                                {/* CONSULT INPUT BLOCK (If no results or requesting new) */}
                                {!consultResult && (
                                    <div style={{
                                        padding: '16px 24px 24px',
                                        background: 'var(--surface)',
                                        borderTop: '1px solid var(--border)',
                                        flexShrink: 0,
                                        zIndex: 5,
                                    }}>
                                        {/* Collapsible Symptom Builder Helper */}
                                        <div style={{ maxWidth: 800, margin: '0 auto 12px' }}>
                                            <button
                                                onClick={() => setShowHelper(!showHelper)}
                                                style={{
                                                    background: 'var(--surface)',
                                                    border: '1.5px solid var(--border)',
                                                    borderRadius: 12,
                                                    padding: '6px 12px',
                                                    fontSize: 12,
                                                    fontWeight: 700,
                                                    color: 'var(--primary)',
                                                    cursor: 'pointer',
                                                    display: 'flex',
                                                    alignItems: 'center',
                                                    gap: 6,
                                                    marginLeft: 'auto',
                                                    boxShadow: '0 2px 8px rgba(0,0,0,0.03)',
                                                }}
                                            >
                                                <Sliders size={12} />
                                                {showHelper ? 'Đóng trợ lý triệu chứng' : 'Trợ lý cấu trúc triệu chứng (Safety Test)'}
                                            </button>

                                            <AnimatePresence>
                                                {showHelper && (
                                                    <motion.div
                                                        initial={{ opacity: 0, height: 0 }}
                                                        animate={{ opacity: 1, height: 'auto' }}
                                                        exit={{ opacity: 0, height: 0 }}
                                                        style={{
                                                            overflow: 'hidden',
                                                            background: 'var(--surface)',
                                                            border: '1.5px solid var(--border)',
                                                            borderRadius: 16,
                                                            padding: 16,
                                                            marginTop: 8,
                                                            display: 'flex',
                                                            flexDirection: 'column',
                                                            gap: 12,
                                                            boxShadow: '0 10px 25px -5px rgba(0,0,0,0.05)',
                                                        }}
                                                    >
                                                        <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.3px' }}>
                                                            Nhấp để tự động thêm mẫu triệu chứng & kiểm thử lớp an toàn (Safety Layer):
                                                        </div>

                                                        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1.8fr', gap: 16 }}>
                                                            <div>
                                                                <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginBottom: 6 }}>
                                                                    👶 Nhóm đối tượng:
                                                                </span>
                                                                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                                                    {[
                                                                        { label: 'Người lớn', value: 'Tôi là người lớn' },
                                                                        { label: 'Trẻ em (5 tuổi)', value: 'Bé nhà tôi 5 tuổi' },
                                                                        { label: 'Phụ nữ mang thai', value: 'Tôi đang mang thai 3 tháng đầu' }
                                                                    ].map((item, idx) => (
                                                                        <button
                                                                            key={idx}
                                                                            onClick={() => appendHelperText(item.value)}
                                                                            style={{
                                                                                padding: '5px 9px', fontSize: 11, borderRadius: 8,
                                                                                border: '1px solid var(--border)', background: 'var(--background)',
                                                                                color: 'var(--text-secondary)', cursor: 'pointer', fontWeight: 600
                                                                            }}
                                                                        >
                                                                            {item.label}
                                                                        </button>
                                                                    ))}
                                                                </div>
                                                            </div>

                                                            <div>
                                                                <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginBottom: 6 }}>
                                                                    ⚠️ Tiền sử bệnh nền (Kiểm tra chặn chống chỉ định):
                                                                </span>
                                                                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                                                    {[
                                                                        { label: 'Viêm gan B / Gan yếu', value: 'tiền sử bị viêm gan B' },
                                                                        { label: 'Viêm loét dạ dày', value: 'bị viêm loét dạ dày tá tràng' },
                                                                        { label: 'Dị ứng Aspirin', value: 'dị ứng với Aspirin và các hạt giảm đau NSAID' }
                                                                    ].map((item, idx) => (
                                                                        <button
                                                                            key={idx}
                                                                            onClick={() => appendHelperText(item.value)}
                                                                            style={{
                                                                                padding: '5px 9px', fontSize: 11, borderRadius: 8,
                                                                                border: '1px solid #fee2e2', background: '#fff5f5',
                                                                                color: '#ef4444', cursor: 'pointer', fontWeight: 600
                                                                            }}
                                                                        >
                                                                            {item.label}
                                                                        </button>
                                                                    ))}
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div>
                                                            <span style={{ fontSize: 11, fontWeight: 700, color: 'var(--text-primary)', display: 'block', marginBottom: 6 }}>
                                                                🤒 Mô tả Triệu chứng mẫu:
                                                            </span>
                                                            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                                                                {[
                                                                    { label: 'Đau đầu dữ dội', value: 'đau nhức vùng đầu dữ dội kèm chóng mặt' },
                                                                    { label: 'Sốt cao 39°C', value: 'sốt cao liên tục 39 độ hai ngày nay' },
                                                                    { label: 'Ho đờm ngứa cổ', value: 'ho có đờm xanh ngứa cổ họng' },
                                                                    { label: 'Đau dạ dày âm ỉ', value: 'đau bụng âm ỉ vùng thượng vị sau ăn' }
                                                                ].map((item, idx) => (
                                                                    <button
                                                                        key={idx}
                                                                        onClick={() => appendHelperText(item.value)}
                                                                        style={{
                                                                            padding: '5px 9px', fontSize: 11, borderRadius: 8,
                                                                            border: '1px solid var(--border)', background: 'var(--background)',
                                                                            color: 'var(--text-secondary)', cursor: 'pointer', fontWeight: 600
                                                                        }}
                                                                    >
                                                                        {item.label}
                                                                    </button>
                                                                ))}
                                                            </div>
                                                        </div>
                                                    </motion.div>
                                                )}
                                            </AnimatePresence>
                                        </div>

                                        <div style={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: 10,
                                            padding: '6px 6px 6px 16px',
                                            background: isInputFocused ? 'var(--surface)' : 'var(--background)',
                                            borderRadius: '18px',
                                            border: '1.5px solid',
                                            borderColor: isInputFocused ? 'var(--primary)' : 'var(--border)',
                                            maxWidth: 800,
                                            margin: '0 auto',
                                            boxShadow: '0 8px 30px rgba(0,0,0,0.06)'
                                        }}>
                                            <textarea
                                                rows={1}
                                                value={consultSymptoms}
                                                onChange={(e) => {
                                                    setConsultSymptoms(e.target.value);
                                                    e.target.style.height = 'auto';
                                                    e.target.style.height = Math.min(e.target.scrollHeight, 100) + 'px';
                                                }}
                                                onFocus={() => setIsInputFocused(true)}
                                                onBlur={() => setIsInputFocused(false)}
                                                placeholder="Ví dụ: Bé nhà tôi bị ho kèm đờm xanh, sốt nhẹ 38 độ hai ngày nay..."
                                                disabled={isConsultLoading}
                                                style={{
                                                    flex: 1,
                                                    background: 'transparent',
                                                    border: 'none',
                                                    outline: 'none',
                                                    color: 'var(--text-primary)',
                                                    fontSize: '14px',
                                                    lineHeight: 1.5,
                                                    resize: 'none',
                                                    margin: '4px 0',
                                                    maxHeight: 100,
                                                    fontFamily: 'inherit',
                                                }}
                                            />
                                            <motion.button
                                                whileHover={consultSymptoms.trim() ? { scale: 1.05 } : {}}
                                                whileTap={consultSymptoms.trim() ? { scale: 0.95 } : {}}
                                                onClick={() => handleConsultSubmit()}
                                                disabled={!consultSymptoms.trim() || isConsultLoading}
                                                style={{
                                                    width: 36, height: 36,
                                                    borderRadius: '12px',
                                                    background: (!consultSymptoms.trim() || isConsultLoading) ? 'var(--border)' : 'var(--primary)',
                                                    color: 'white',
                                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                                    cursor: (!consultSymptoms.trim() || isConsultLoading) ? 'not-allowed' : 'pointer',
                                                    flexShrink: 0,
                                                }}
                                            >
                                                {isConsultLoading ? (
                                                    <Activity size={15} className="animate-spin" />
                                                ) : (
                                                    <Send size={15} strokeWidth={2.5} />
                                                )}
                                            </motion.button>
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Right Side: Recommendation Results Card Lists */}
                            <div style={{
                                width: consultResult ? '400px' : '0px',
                                transition: 'width 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                overflow: 'hidden',
                                background: 'var(--surface)',
                                display: 'flex',
                                flexDirection: 'column',
                                flexShrink: 0,
                            }}>
                                {consultResult && (
                                    <div style={{
                                        padding: '24px',
                                        flex: 1,
                                        overflowY: 'auto',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        gap: 16,
                                        scrollbarWidth: 'thin',
                                    }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <h3 style={{ fontSize: 15, fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>
                                                Đề xuất thuốc
                                            </h3>
                                            <button
                                                onClick={handleNewConsult}
                                                style={{
                                                    background: 'none', border: 'none', color: 'var(--primary)',
                                                    fontSize: 12, fontWeight: 700, cursor: 'pointer',
                                                    display: 'flex', alignItems: 'center', gap: 4
                                                }}
                                            >
                                                <RotateCcw size={12} />
                                                Tư vấn mới
                                            </button>
                                        </div>

                                        <ConsultResultPanel
                                            result={consultResult}
                                            sessionId={sessionId || ''}
                                            onAddMedicine={handleAddMedicineClick}
                                            onNewConsult={handleNewConsult}
                                        />
                                    </div>
                                )}
                            </div>
                        </motion.div>
                    )}
                </AnimatePresence>
            </div>

            {/* Modals */}
            <ConfirmModal
                isOpen={showConfirm}
                onClose={() => setShowConfirm(false)}
                onConfirm={() => {
                    setShowConfirm(false);
                    setConversationId(null);
                    setMessages([]);
                    localStorage.setItem('medi_ai_chat_pref', 'NEW');
                }}
                title={t('ai_chat.delete_history_title')}
                message={t('ai_chat.delete_history_msg')}
                confirmText={t('ai_chat.confirm_delete')}
            />

            <HistorySidebar
                isOpen={showHistory}
                onClose={() => setShowHistory(false)}
                onSelectConversation={handleSelectConversation}
                currentConversationId={conversationId}
                onSelectSession={handleSelectSession}
                currentSessionId={sessionId}
                onNewChat={handleNewChat}
                initialTab={pageMode}
            />

            {selectedMed && (
                <QuickAddMedicineModal
                    isOpen={isAddModalOpen}
                    onClose={() => {
                        setIsAddModalOpen(false);
                        setSelectedMed(null);
                    }}
                    medicine={selectedMed}
                    sessionId={sessionId || ''}
                    onSuccess={handleCabinetSuccess}
                />
            )}
        </div>
    );
}
