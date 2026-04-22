'use client';

import { motion, AnimatePresence, Variants } from 'framer-motion';
import { usePathname } from 'next/navigation';

const pageVariants: Variants = {
    initial: {
        opacity: 0,
        y: 8, // giảm từ 12 → 8: ít trượt hơn, cảm giác nhanh hơn
    },
    animate: {
        opacity: 1,
        y: 0,
        transition: {
            y: {
                type: 'spring',
                stiffness: 140, // tăng từ 100 → 140: spring căng hơn, nhanh hơn
                damping: 18,    // giảm từ 20 → 18: vẫn mượt, không bật nảy
                mass: 0.6,      // giảm từ 0.8 → 0.6: cảm giác nhẹ hơn, crisp hơn
            },
            opacity: {
                duration: 0.25, // giảm từ 0.4 → 0.25s: fade in nhanh hơn
                ease: "easeOut"
            }
        },
    },
    exit: {
        opacity: 0,
        y: -6,
        transition: {
            duration: 0.15, // giảm từ 0.3 → 0.15s: exit gần như tức thì
            ease: "easeIn"
        },
    },
};

export const PageTransition = ({ children }: { children: React.ReactNode }) => {
    const pathname = usePathname();

    return (
        <AnimatePresence mode="wait" initial={false}>
            <motion.div
                key={pathname}
                variants={pageVariants}
                initial="initial"
                animate="animate"
                exit="exit"
                style={{
                    width: '100%',
                    willChange: 'opacity, transform', // Thông báo cho GPU chuẩn bị tài nguyên
                    transformStyle: 'preserve-3d', // Giảm thiểu hiện tượng rung hình
                }}
            >
                {children}
            </motion.div>
        </AnimatePresence>
    );
};
