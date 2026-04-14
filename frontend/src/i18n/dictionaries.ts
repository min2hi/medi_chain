export const dictionaries = {
    vi: {
        nav: {
            home: 'Trang chủ',
            profile: 'Hồ sơ',
            appointments: 'Lịch hẹn',
            medications: 'Thuốc',
            ai: 'MediAI',
            sharing: 'Chia sẻ',
            settings: 'Cài đặt'
        },
        settings: {
            title: 'Cài đặt',
            account_security: 'TÀI KHOẢN & BẢO MẬT',
            change_password: 'Đổi mật khẩu khóa dữ liệu',
            biometric: 'Biometric / Vân tay',
            recovery_key: 'Sao lưu Recovery Key',
            sessions: 'Phiên đăng nhập',
            devices_count: '{{count}} thiết bị',
            app: 'ỨNG DỤNG',
            notifications: 'Thông báo nhắc nhở',
            theme: 'Chuyển sang Sáng',
            theme_dark: 'Chuyển sang Tối',
            language: 'Ngôn ngữ',
            mobile_app: 'Ứng dụng di động',
            about: 'VỀ MEDICHAIN',
            version: 'Phiên bản',
            latest: 'Mới nhất',
            support: 'Hỗ trợ & Hướng dẫn',
            logout: 'Đăng xuất MediChain',
            only_mobile: 'Chỉ mobile',
            language_desc: 'Chọn ngôn ngữ hiển thị của ứng dụng',
            cancel: 'Hủy',
            apply: 'Áp dụng',
            saving: 'Đang lưu...'
        }
    },
    en: {
        nav: {
            home: 'Home',
            profile: 'Profile',
            appointments: 'Appointments',
            medications: 'Medications',
            ai: 'MediAI',
            sharing: 'Sharing',
            settings: 'Settings'
        },
        settings: {
            title: 'Settings',
            account_security: 'ACCOUNT & SECURITY',
            change_password: 'Change Data Password',
            biometric: 'Biometric / Fingerprint',
            recovery_key: 'Backup Recovery Key',
            sessions: 'Active Sessions',
            devices_count: '{{count}} devices',
            app: 'APPLICATION',
            notifications: 'Reminders & Alerts',
            theme: 'Light Mode',
            theme_dark: 'Dark Mode',
            language: 'Language',
            mobile_app: 'Mobile App',
            about: 'ABOUT MEDICHAIN',
            version: 'Version',
            latest: 'Latest',
            support: 'Support & Guide',
            logout: 'Log out of MediChain',
            only_mobile: 'Mobile only',
            language_desc: 'Choose your preferred application language',
            cancel: 'Cancel',
            apply: 'Apply',
            saving: 'Saving...'
        }
    }
};

export type Locale = keyof typeof dictionaries;
