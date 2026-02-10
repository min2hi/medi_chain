import { Home, ClipboardList, Calendar, Share2, Pill, Settings, BrainCircuit } from 'lucide-react';

export const NAV_ITEMS = [
    { label: 'Trang chủ', icon: Home, href: '/' },
    { label: 'Hồ sơ', icon: ClipboardList, href: '/ho-so' },
    { label: 'Lịch hẹn', icon: Calendar, href: '/lich-hen' },
    { label: 'Thuốc', icon: Pill, href: '/thuoc' },
    { label: 'MediAI', icon: BrainCircuit, href: '/tu-van' },
    { label: 'Chia sẻ', icon: Share2, href: '/chia-se' },
    { label: 'Cài đặt', icon: Settings, href: '/cai-dat' },
];
