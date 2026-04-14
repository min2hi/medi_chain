'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { dictionaries, Locale } from './dictionaries';

type I18nContextType = {
    locale: Locale;
    setLocale: (loc: Locale) => void;
    t: (key: string, params?: Record<string, string | number>) => string;
};

const I18nContext = createContext<I18nContextType | null>(null);

export const I18nProvider = ({ children }: { children: React.ReactNode }) => {
    const [locale, setLocaleState] = useState<Locale>('vi'); // Default
    const [hydrated, setHydrated] = useState(false);

    useEffect(() => {
        // Hydrate from localStorage
        const saved = localStorage.getItem('locale') as Locale;
        if (saved && dictionaries[saved]) {
            setLocaleState(saved);
        }
        setHydrated(true);
        
        // Listen to arbitrary window events for cross-component locale sync without page reload
        const handleLocaleChange = () => {
             const updated = localStorage.getItem('locale') as Locale;
             if (updated && dictionaries[updated]) {
                 setLocaleState(updated);
             }
        };
        window.addEventListener('locale-changed', handleLocaleChange);
        return () => window.removeEventListener('locale-changed', handleLocaleChange);
    }, []);

    const setLocale = (newLocale: Locale) => {
        setLocaleState(newLocale);
        localStorage.setItem('locale', newLocale);
        window.dispatchEvent(new Event('locale-changed'));
    };

    const t = (key: string, params?: Record<string, string | number>): string => {
        if (!hydrated) {
            // To prevent hydration mismatch, return fallback 'vi' strings or empty during SSR,
            // but returning the 'vi' dictionary is usually safe if the HTML is rendered in vi.
        }

        const keys = key.split('.');
        let val: any = dictionaries[locale];

        for (const k of keys) {
            if (val && typeof val === 'object' && k in val) {
                val = val[k];
            } else {
                return key; // Fallback to key if not found
            }
        }

        let result = val as string;

        // Simple interpolation
        if (params && typeof result === 'string') {
            Object.entries(params).forEach(([k, v]) => {
                result = result.replace(new RegExp(`{{${k}}}`, 'g'), String(v));
            });
        }

        return result;
    };

    return (
        <I18nContext.Provider value={{ locale, setLocale, t }}>
            {children}
        </I18nContext.Provider>
    );
};

export const useTranslation = () => {
    const context = useContext(I18nContext);
    if (!context) {
        throw new Error('useTranslation must be used within an I18nProvider');
    }
    return context;
};
