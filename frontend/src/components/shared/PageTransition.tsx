'use client';

import { motion, AnimatePresence, Variants } from 'framer-motion';
import { usePathname } from 'next/navigation';

const pageVariants: Variants = {
    initial: {
        opacity: 0,
        y: 12, // Tăng nhẹ khoảng cách trượt để cảm nhận rõ Spring
    },
    animate: {
        opacity: 1,
        y: 0,
        transition: {
            y: {
                type: 'spring',
                stiffness: 100, // Tốc độ vừa phải, chuyên nghiệp
                damping: 20,    // Không bị bật nảy, dừng lại cực êm
                mass: 0.8,      // Cảm giác nội dung nhẹ nhàng, thanh thoát
            },
            opacity: {
                duration: 0.4,
                ease: "easeOut"
            }
        },
    },
    exit: {
        opacity: 0,
        y: -12,
        transition: {
            duration: 0.3,
            ease: "easeInOut"
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
