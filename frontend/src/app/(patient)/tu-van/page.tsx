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
import { ConsultResultPanel, SafetyWarningsPanel } from '@/components/tu-van/ConsultResultPanel';
import { QuickAddMedicineModal } from '@/components/tu-van/QuickAddMedicineModal';
import { useTranslation } from '@/i18n/I18nProvider';
import { dictionaries, Locale } from '@/i18n/dictionaries';

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
                p: ({ children }) => <p className="my-1.5 leading-relaxed">{children}</p>,
                strong: ({ children }) => <strong className="font-bold text-inherit">{children}</strong>,
                em: ({ children }) => <em className="italic opacity-90">{children}</em>,
                ul: ({ children }) => <ul className="my-2 pl-5 list-disc">{children}</ul>,
                ol: ({ children }) => <ol className="my-2 pl-5 list-decimal">{children}</ol>,
                li: ({ children }) => <li className="my-1 leading-relaxed">{children}</li>,
                h1: ({ children }) => <h1 className="text-lg font-extrabold my-4 text-primary">{children}</h1>,
                h2: ({ children }) => <h2 className="text-base font-bold my-3 text-primary">{children}</h2>,
                h3: ({ children }) => <h3 className="text-sm font-semibold my-2 opacity-90">{children}</h3>,
                hr: () => <hr className="border-none border-t border-border my-3" />,
                blockquote: ({ children }) => (
                    <blockquote className="border-l-4 border-primary pl-4 my-3 opacity-80 italic bg-primary/5 p-3 rounded-r-xl">
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
        <div className="flex items-end gap-3">
            <div className="w-9 h-9 rounded-xl bg-emerald-600 flex items-center justify-center shrink-0 text-sm font-extrabold text-white shadow-sm border border-transparent">
                M
            </div>
            <div className="px-5 py-3.5 bg-surface border border-border rounded-[20px] rounded-bl-none flex items-center gap-1 shadow-sm">
                {[0, 1, 2].map(i => (
                    <motion.span
                        key={i}
                        animate={{ opacity: [0.3, 1, 0.3], scale: [1, 1.2, 1] }}
                        transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.2 }}
                        className="w-1.5 h-1.5 rounded-full bg-primary block"
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

    // Sidebar & history states
    const [showHistory, setShowHistory] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);

    // Chat Tab states
    const [messages, setMessages] = useState<AIMessage[]>([]);
    const [chatInput, setChatInput] = useState('');
    const [isChatLoading, setIsChatLoading] = useState(false);
    const [conversationId, setConversationId] = useState<string | null>(null);
    const [isFetchingHistory, setIsFetchingHistory] = useState(false);

    // Consult Tab states
    const [consultSymptoms, setConsultSymptoms] = useState('');
    const [isConsultLoading, setIsConsultLoading] = useState(false);
    const [consultResult, setConsultResult] = useState<RecommendationResponse | null>(null);
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [showHelper, setShowHelper] = useState(false);

    // Cabinet quick add modal states
    const [selectedMed, setSelectedMed] = useState<Medicine | null>(null);
    const [isAddModalOpen, setIsAddModalOpen] = useState(false);

    const [isInputFocused, setIsInputFocused] = useState(false);

    const messagesContainerRef = useRef<HTMLDivElement>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    // Init page state based on route query or localStorage
    useEffect(() => {
        const urlParams = new URLSearchParams(window.location.search);
        const mode = urlParams.get('mode');
        if (mode === 'consult') {
            setPageMode('CONSULT');
        }

        const sessId = urlParams.get('sessionId');
        if (sessId) {
            setPageMode('CONSULT');
            handleSelectSession(sessId);
        } else {
            const savedPref = localStorage.getItem('medi_ai_chat_pref');
            if (savedPref === 'NEW' || !savedPref) {
                setConversationId(null);
                setMessages([]);
            } else {
                const loadInitialChat = async () => {
                    setIsFetchingHistory(true);
                    try {
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
                loadInitialChat();
            }
        }
    }, []);

    // Scroll to bottom on new messages
    useEffect(() => {
        if (messagesEndRef.current) {
            messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [messages, isChatLoading]);

    // Handle autosizing textarea for CHAT
    useEffect(() => {
        if (textareaRef.current) {
            textareaRef.current.style.height = 'auto';
            textareaRef.current.style.height = Math.min(textareaRef.current.scrollHeight, 100) + 'px';
        }
    }, [chatInput]);

    const loadMessages = async (id: string) => {
        setIsFetchingHistory(true);
        try {
            const msgRes = await AIApi.getMessages(id);
            if (msgRes.success) {
                setMessages(msgRes.data || []);
            }
        } catch (e) {
            console.error("Failed to load messages:", e);
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
        setIsConsultLoading(true);
        try {
            const res = await RecommendationApi.getSessionDetail(sId);
            if (res.success && res.data) {
                const resultData = res.data;
                setConsultResult(resultData);
                setSessionId(resultData.sessionId);
                setConsultSymptoms(resultData.symptoms || '');
                setShowHistory(false);
            }
        } catch (e) {
            console.error('Failed to load session detail:', e);
        } finally {
            setIsConsultLoading(false);
        }
    };

    const handleNewChat = () => {
        setPageMode('CHAT');
        localStorage.setItem('medi_ai_chat_pref', 'NEW');
        setConversationId(null);
        setMessages([]);
        setChatInput('');
        setTimeout(() => textareaRef.current?.focus(), 150);
    };

    const handleNewConsult = () => {
        setPageMode('CONSULT');
        setConsultResult(null);
        setSessionId(null);
        setConsultSymptoms('');
        setShowHelper(false);
    };

    const handleSend = async (textOverride?: string) => {
        const text = (textOverride ?? chatInput).trim();
        if (!text || isChatLoading) return;

        const tempId = `temp-${Date.now()}`;
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
                id: `err-${Date.now()}`,
                role: 'ASSISTANT',
                content: msg,
                createdAt: new Date().toISOString(),
            }]);
        } finally {
            setIsChatLoading(false);
        }
    };

    const appendHelperText = (text: string) => {
        setConsultSymptoms(prev => {
            const trimmed = prev.trim();
            if (!trimmed) return text;
            if (trimmed.endsWith('.') || trimmed.endsWith(',')) {
                return `${trimmed} ${text.toLowerCase()}`;
            }
            return `${trimmed}, ${text.toLowerCase()}`;
        });
    };

    const handleConsultSubmit = async () => {
        if (consultSymptoms.trim().length < 5 || isConsultLoading) return;
        setIsConsultLoading(true);
        setConsultResult(null);
        setSessionId(null);

        try {
            const res = await AIApi.consult(consultSymptoms);
            if (res.success && res.data) {
                setConsultResult(res.data);
                setSessionId(res.data.sessionId || null);
            } else {
                alert(res.message || 'Lỗi hệ thống khi phân tích triệu chứng.');
            }
        } catch (err) {
            console.error(err);
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
        <div className="flex flex-col h-[calc(100vh-100px)] bg-background rounded-[36px] border border-border overflow-hidden shadow-2xl relative">
            {/* ──────── HEADER ──────── */}
            <header className="px-6 py-4 bg-surface border-b border-border flex items-center justify-between shrink-0 z-10">
                <div className="flex items-center gap-3.5">
                    <div className="relative">
                        <motion.div
                            whileHover={{ scale: 1.05 }}
                            className="w-12 h-12 rounded-2xl bg-emerald-600 flex items-center justify-center text-xl font-black text-white shadow-md cursor-pointer border border-transparent"
                        >
                            M
                        </motion.div>
                        <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 bg-emerald-500 rounded-full border-2 border-surface" />
                    </div>

                    <div>
                        <div className="font-extrabold text-base text-primary tracking-tight">
                            Tư vấn sức khỏe AI
                        </div>
                        <div className="text-xs text-emerald-500 font-semibold flex items-center gap-1.5">
                            <motion.span
                                animate={{ opacity: [0.4, 1, 0.4] }}
                                transition={{ duration: 2, repeat: Infinity }}
                                className="w-1.5 h-1.5 bg-emerald-500 rounded-full"
                            />
                            Hệ thống hoạt động ổn định
                        </div>
                    </div>
                </div>

                {/* Segmented Tab Switcher */}
                <div className="flex bg-background border border-border p-0.5 rounded-2xl items-center gap-1">
                    <button
                        onClick={() => setPageMode('CHAT')}
                        className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all border-none cursor-pointer ${pageMode === 'CHAT' ? 'bg-surface text-primary shadow-sm' : 'bg-transparent text-secondary hover:text-primary'}`}
                    >
                        <MessageSquare size={14} />
                        Trò chuyện AI
                    </button>
                    <button
                        onClick={() => setPageMode('CONSULT')}
                        className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all border-none cursor-pointer ${pageMode === 'CONSULT' ? 'bg-surface text-primary shadow-sm' : 'bg-transparent text-secondary hover:text-primary'}`}
                    >
                        <BrainCircuit size={14} />
                        Tư vấn thuốc
                    </button>
                </div>

                <div className="flex gap-2.5">
                    <motion.button
                        whileHover={{ y: -2, backgroundColor: 'var(--background)', color: 'var(--primary)' }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => pageMode === 'CHAT' ? handleNewChat() : handleNewConsult()}
                        title="Tạo mới"
                        className="w-10 h-10 rounded-xl bg-transparent border border-border text-muted hover:text-primary hover:border-primary/50 transition-colors flex items-center justify-center cursor-pointer"
                    >
                        <Plus size={20} />
                    </motion.button>
                    <motion.button
                        whileHover={{ y: -2, backgroundColor: 'var(--background)', color: 'var(--primary)' }}
                        whileTap={{ scale: 0.95 }}
                        onClick={() => setShowHistory(true)}
                        title="Lịch sử"
                        className="w-10 h-10 rounded-xl bg-transparent border border-border text-muted hover:text-primary hover:border-primary/50 transition-colors flex items-center justify-center cursor-pointer"
                    >
                        <History size={20} />
                    </motion.button>
                    {pageMode === 'CHAT' && (
                        <motion.button
                            whileHover={{ y: -2, backgroundColor: 'var(--background)', color: '#ef4444' }}
                            whileTap={{ scale: 0.95 }}
                            onClick={() => setShowConfirm(true)}
                            title="Xóa lịch sử chat"
                            className="w-10 h-10 rounded-xl bg-transparent border border-border text-muted hover:text-red-500 hover:border-red-500/50 transition-colors flex items-center justify-center cursor-pointer"
                        >
                            <Trash2 size={20} />
                        </motion.button>
                    )}
                </div>
            </header>

            {/* ──────── MAIN AREA ──────── */}
            <div className="flex flex-1 overflow-hidden">
                <AnimatePresence mode="wait">
                    {pageMode === 'CHAT' ? (
                        <motion.div
                            key="chat-tab"
                            initial={{ opacity: 0, x: -15 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: 15 }}
                            transition={{ duration: 0.25 }}
                            className="flex flex-col flex-1 h-full"
                        >
                            {/* MESSAGES */}
                            <div
                                ref={messagesContainerRef}
                                className="flex-1 overflow-y-auto p-6 flex flex-col gap-2 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent bg-primary/[0.005]"
                            >
                                {messages.length === 0 && !isChatLoading && !isFetchingHistory && (
                                    <div className="flex flex-col items-center mx-auto my-10 gap-5 py-5 max-w-lg text-center">
                                        <div className="text-center max-w-[500px]">
                                            <motion.div
                                                animate={{ y: [0, -10, 0] }}
                                                transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
                                                className="w-20 h-20 rounded-3xl bg-emerald-600 flex items-center justify-center mx-auto mb-4 select-none shadow-xl shadow-emerald-500/20 text-4xl font-black text-white border border-transparent"
                                            >
                                                M
                                            </motion.div>
                                            <h2 className="text-2xl font-extrabold text-primary mb-2 tracking-tight">
                                                {t('ai_chat.welcome_title')} <Sparkles size={20} className="inline text-amber-455" />
                                            </h2>
                                            <p className="text-[14.5px] text-secondary leading-relaxed max-w-md mx-auto">
                                                {t('ai_chat.welcome_desc')}
                                            </p>
                                        </div>
                                    </div>
                                )}

                                {messages.map((msg, idx) => {
                                    const isUser = msg.role === 'USER';
                                    const prevMsg = messages[idx - 1];
                                    const isSameRole = prevMsg?.role === msg.role;
                                    const topGap = isSameRole ? 'mt-1' : 'mt-5';

                                    return (
                                        <div
                                            key={msg.id}
                                            className={`flex ${isUser ? 'justify-end' : 'justify-start'} items-end gap-3 ${topGap}`}
                                        >
                                            {!isUser && (
                                                <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-xs font-extrabold text-white shrink-0 ${isSameRole ? 'bg-transparent invisible' : 'bg-emerald-600 shadow-sm border border-transparent'}`}>
                                                    M
                                                </div>
                                            )}

                                            <div className={`max-w-[75%] flex flex-col ${isUser ? 'items-end' : 'items-start'}`}>
                                                <div className={`px-[18px] py-3 text-[15px] leading-relaxed break-words border ${isUser ? 'bg-primary text-white border-transparent shadow-md shadow-primary/10' : 'bg-surface text-primary border-border shadow-sm'} ${isUser ? (isSameRole ? 'rounded-[22px] rounded-br-[6px]' : 'rounded-[22px] rounded-br-[6px]') : (isSameRole ? 'rounded-[22px] rounded-bl-[6px]' : 'rounded-[22px] rounded-bl-[6px]')}`}>
                                                    {isUser
                                                        ? <span className="white-space-pre-wrap">{msg.content}</span>
                                                        : <MarkdownContent content={msg.content} />
                                                    }
                                                </div>
                                                {(idx === messages.length - 1 || messages[idx + 1]?.role !== msg.role) && (
                                                    <span className="text-[11px] text-muted mt-1.5 font-medium">
                                                        {formatTime(msg.createdAt)}
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                    );
                                })}

                                {isFetchingHistory && (
                                    <div className="flex flex-col gap-4 py-2">
                                        {[1, 2, 3].map(i => (
                                            <div key={i} className="flex gap-3 items-end">
                                                <div className="w-9 h-9 rounded-xl bg-border shrink-0 animate-pulse" />
                                                <div className="h-14 rounded-2xl bg-border flex-1 animate-pulse" style={{ opacity: 0.6 - i * 0.15 }} />
                                            </div>
                                        ))}
                                    </div>
                                )}

                                {isChatLoading && (
                                    <div className="mt-5">
                                        <TypingBubble />
                                    </div>
                                )}
                                <div ref={messagesEndRef} />
                            </div>

                            {/* CHAT INPUT AREA */}
                            <div className="px-5 py-3 pb-5 bg-surface border-t border-border shrink-0">
                                <div className={`flex items-center gap-2.5 pl-4 pr-1.5 py-1.5 rounded-2xl border transition-all duration-300 ${isInputFocused ? 'bg-surface border-primary ring-2 ring-primary/10' : 'bg-background border-border'}`}>
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
                                        className="flex-1 bg-transparent border-none outline-none text-primary text-sm leading-normal resize-none my-1 max-h-[100px] font-sans"
                                    />
                                    <motion.button
                                        whileHover={chatInput.trim() ? { scale: 1.05 } : {}}
                                        whileTap={chatInput.trim() ? { scale: 0.95 } : {}}
                                        onClick={() => handleSend()}
                                        disabled={!chatInput.trim() || isChatLoading}
                                        className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 transition-all ${(!chatInput.trim() || isChatLoading) ? 'bg-border text-muted cursor-not-allowed' : 'bg-primary text-white cursor-pointer hover:shadow-lg hover:shadow-primary/20'}`}
                                    >
                                        <Send size={15} strokeWidth={2.5} />
                                    </motion.button>
                                </div>

                                <div className="flex justify-center items-center mt-3 opacity-50 text-[11px] text-muted font-medium gap-3">
                                    <span>{t('ai_chat.hint_newline')}</span>
                                    <span className="w-1 h-1 bg-current rounded-full" />
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
                            className="flex flex-1 h-full overflow-hidden bg-background"
                        >
                            {/* Left Side: Result Details (If exists) / Description Guide */}
                            <div className={`flex-1 flex flex-col h-full overflow-hidden ${consultResult ? 'border-r border-border' : 'border-none'}`}>
                                {/* Scrollable content body */}
                                <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent">
                                    {consultResult ? (
                                        <div className="flex flex-col gap-4">
                                            {/* Symptoms Summary */}
                                            <div className="bg-surface border border-border rounded-2xl p-4 relative shadow-sm">
                                                <span className="absolute -top-2 left-4 text-[10px] font-bold bg-background px-2 text-primary tracking-wider uppercase">
                                                    MÔ TẢ TRIỆU CHỨNG CỦA BẠN
                                                </span>
                                                <p className="text-sm font-semibold text-primary m-0 leading-relaxed">
                                                    {consultSymptoms}
                                                </p>
                                            </div>

                                            {/* Safety warnings (Moved from right side to left side) */}
                                            {consultResult.safetyWarnings && consultResult.safetyWarnings.length > 0 && (
                                                <SafetyWarningsPanel warnings={consultResult.safetyWarnings} />
                                            )}

                                            {/* AI Diagnosis explanation */}
                                            {consultResult.message?.content && (
                                                <div className="bg-surface border border-border rounded-2xl p-5 shadow-sm">
                                                    <div className="flex items-center gap-2 mb-3">
                                                        <Sparkles size={16} className="text-primary" />
                                                        <h3 className="text-sm font-extrabold text-primary m-0">
                                                            Phân tích y tế & Giải thích thuốc
                                                        </h3>
                                                    </div>
                                                    <div className="text-[13.5px] text-secondary leading-relaxed">
                                                        <MarkdownContent content={consultResult.message.content} />
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    ) : (
                                        <div className="flex flex-col items-center mx-auto my-10 gap-5 py-5 max-w-lg text-center">
                                            <div className="text-center max-w-[520px]">
                                                <motion.div
                                                    animate={{
                                                        scale: [1, 1.03, 1],
                                                        rotate: [0, 2, -2, 0]
                                                    }}
                                                    transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
                                                    className="w-20 h-20 rounded-3xl bg-gradient-to-br from-indigo-500 to-indigo-700 flex items-center justify-center mx-auto mb-4 shadow-lg shadow-indigo-500/20 text-white"
                                                >
                                                    <BrainCircuit size={36} />
                                                </motion.div>
                                                <h2 className="text-xl font-extrabold text-primary mb-2">
                                                    Tư vấn & Gợi ý thuốc AI
                                                </h2>
                                                <p className="text-sm text-secondary leading-relaxed m-0">
                                                    Mô tả các triệu chứng của bạn thật chi tiết (bao gồm thời gian, mức độ, tiền sử bệnh nền). Recommendation Engine sẽ phân tích và đưa ra giải pháp an toàn nhất.
                                                </p>
                                            </div>
                                        </div>
                                    )}
                                </div>

                                {/* CONSULT INPUT BLOCK (If no results or requesting new) */}
                                {!consultResult && (
                                    <div className="px-6 py-4 pb-6 bg-surface border-t border-border shrink-0 z-10">
                                        {/* Collapsible Symptom Builder Helper */}
                                        <div className="max-w-[800px] mx-auto mb-3">
                                            <button
                                                onClick={() => setShowHelper(!showHelper)}
                                                className="bg-surface border border-border rounded-xl px-3 py-1.5 text-xs font-bold text-primary cursor-pointer flex items-center gap-1.5 ml-auto shadow-sm"
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
                                                        className="overflow-hidden bg-surface border border-border rounded-2xl p-4 mt-2 flex flex-col gap-3 shadow-md"
                                                    >
                                                        <div className="text-[11px] font-bold text-muted uppercase tracking-wider">
                                                            Nhấp để tự động thêm mẫu triệu chứng & kiểm thử lớp an toàn (Safety Layer):
                                                        </div>

                                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                            <div>
                                                                <span className="text-[11px] font-bold text-primary block mb-1.5">
                                                                    👶 Nhóm đối tượng:
                                                                </span>
                                                                <div className="flex gap-1.5 flex-wrap">
                                                                    {[
                                                                        { label: 'Người lớn', value: 'Tôi là người lớn' },
                                                                        { label: 'Trẻ em (5 tuổi)', value: 'Bé nhà tôi 5 tuổi' },
                                                                        { label: 'Phụ nữ mang thai', value: 'Tôi đang mang thai 3 tháng đầu' }
                                                                    ].map((item, idx) => (
                                                                        <button
                                                                            key={idx}
                                                                            onClick={() => appendHelperText(item.value)}
                                                                            className="px-2.5 py-1 text-[11px] rounded-lg border border-border bg-background text-secondary hover:text-primary hover:border-primary transition-colors font-semibold cursor-pointer"
                                                                        >
                                                                            {item.label}
                                                                        </button>
                                                                    ))}
                                                                </div>
                                                            </div>

                                                            <div>
                                                                <span className="text-[11px] font-bold text-primary block mb-1.5">
                                                                    ⚠️ Tiền sử bệnh nền (Kiểm tra chặn chống chỉ định):
                                                                </span>
                                                                <div className="flex gap-1.5 flex-wrap">
                                                                    {[
                                                                        { label: 'Gan yếu / Viêm gan B', value: 'tiền sử bị viêm gan B' },
                                                                        { label: 'Viêm loét dạ dày', value: 'bị viêm loét dạ dày tá tràng' },
                                                                        { label: 'Dị ứng Aspirin', value: 'dị ứng với Aspirin và các hạt giảm đau NSAID' }
                                                                    ].map((item, idx) => (
                                                                        <button
                                                                            key={idx}
                                                                            onClick={() => appendHelperText(item.value)}
                                                                            className="px-2.5 py-1 text-[11px] rounded-lg border border-red-200 bg-red-50/50 text-red-600 hover:bg-red-50 hover:border-red-400 transition-colors font-semibold cursor-pointer"
                                                                        >
                                                                            {item.label}
                                                                        </button>
                                                                    ))}
                                                                </div>
                                                            </div>
                                                        </div>

                                                        <div>
                                                            <span className="text-[11px] font-bold text-primary block mb-1.5">
                                                                🤒 Mô tả Triệu chứng mẫu:
                                                            </span>
                                                            <div className="flex gap-1.5 flex-wrap">
                                                                {[
                                                                    { label: 'Đau đầu dữ dội', value: 'đau nhức vùng đầu dữ dội kèm chóng mặt' },
                                                                    { label: 'Sốt cao 39°C', value: 'sốt cao liên tục 39 độ hai ngày nay' },
                                                                    { label: 'Ho đờm ngứa cổ', value: 'ho có đờm xanh ngứa cổ họng' },
                                                                    { label: 'Đau dạ dày âm ỉ', value: 'đau bụng âm ỉ vùng thượng vị sau ăn' }
                                                                ].map((item, idx) => (
                                                                    <button
                                                                        key={idx}
                                                                        onClick={() => appendHelperText(item.value)}
                                                                        className="px-2.5 py-1 text-[11px] rounded-lg border border-border bg-background text-secondary hover:text-primary hover:border-primary transition-colors font-semibold cursor-pointer"
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

                                        <div className={`flex items-center gap-2.5 pl-4 pr-1.5 py-1.5 rounded-2xl border transition-all duration-300 max-w-[800px] mx-auto shadow-sm ${isInputFocused ? 'bg-surface border-primary ring-2 ring-primary/10' : 'bg-background border-border'}`}>
                                            <textarea
                                                rows={1}
                                                value={consultSymptoms}
                                                onChange={(e) => {
                                                    setConsultSymptoms(e.target.value);
                                                    e.target.style.height = 'auto';
                                                    e.target.style.height = Math.min(e.target.scrollHeight, 100) + 'px';
                                                }}
                                                onKeyDown={(e) => {
                                                    if (e.key === 'Enter' && !e.shiftKey) {
                                                        e.preventDefault();
                                                        handleConsultSubmit();
                                                    }
                                                }}
                                                onFocus={() => setIsInputFocused(true)}
                                                onBlur={() => setIsInputFocused(false)}
                                                placeholder="Ví dụ: Bé nhà tôi bị ho kèm đờm xanh, sốt nhẹ 38 độ hai ngày nay..."
                                                disabled={isConsultLoading}
                                                className="flex-1 bg-transparent border-none outline-none text-primary text-sm leading-normal resize-none my-1 max-h-[100px] font-sans"
                                            />
                                            <motion.button
                                                whileHover={consultSymptoms.trim().length >= 5 ? { scale: 1.05 } : {}}
                                                whileTap={consultSymptoms.trim().length >= 5 ? { scale: 0.95 } : {}}
                                                onClick={() => handleConsultSubmit()}
                                                disabled={consultSymptoms.trim().length < 5 || isConsultLoading}
                                                className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 transition-all ${(consultSymptoms.trim().length < 5 || isConsultLoading) ? 'bg-border text-muted cursor-not-allowed' : 'bg-primary text-white cursor-pointer hover:shadow-lg hover:shadow-primary/20'}`}
                                            >
                                                {isConsultLoading ? (
                                                    <Activity size={15} className="animate-spin text-white" />
                                                ) : (
                                                    <Send size={15} strokeWidth={2.5} />
                                                )}
                                            </motion.button>
                                        </div>
                                    </div>
                                )}
                            </div>

                            {/* Right Side: Recommendation Results Card Lists */}
                            <div
                                className="transition-all duration-300 ease-[cubic-bezier(0.4,0,0.2,1)] overflow-hidden bg-surface flex flex-col shrink-0"
                                style={{ width: consultResult ? '480px' : '0px' }}
                            >
                                {consultResult && (
                                    <div className="p-6 flex-1 overflow-y-auto flex flex-col gap-4 scrollbar-thin scrollbar-thumb-border scrollbar-track-transparent">
                                        <div className="flex justify-between items-center">
                                            <h3 className="text-sm font-extrabold text-primary m-0">
                                                Đề xuất thuốc
                                            </h3>
                                            <button
                                                onClick={handleNewConsult}
                                                className="bg-transparent border-none color-primary text-xs font-bold cursor-pointer flex items-center gap-1 text-primary hover:opacity-80"
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
