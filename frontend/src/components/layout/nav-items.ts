import { Home, ClipboardList, Calendar, Share2, Pill, Settings, BrainCircuit, HeartPulse, Activity } from 'lucide-react';

export const NAV_ITEMS = [
    { label: 'nav.home', icon: Home, href: '/' },
    { label: 'nav.profile', icon: ClipboardList, href: '/ho-so' },
    { label: 'nav.appointments', icon: Calendar, href: '/lich-hen' },
    { label: 'nav.medications', icon: Pill, href: '/thuoc' },
    { label: 'nav.ai', icon: BrainCircuit, href: '/tu-van' },
    { label: 'nav.health_twin', icon: HeartPulse, href: '/bong-suc-khoe' },
    { label: 'nav.timeline', icon: Activity, href: '/hanh-trinh' },
    { label: 'nav.sharing', icon: Share2, href: '/chia-se' },
    { label: 'nav.settings', icon: Settings, href: '/cai-dat' },
];
