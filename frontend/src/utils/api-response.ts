import { NextResponse } from 'next/server';

/**
 * Utility để chuẩn hóa phản hồi từ API
 */
export const ApiResponse = {
    success(data: unknown, message = 'Thành công', status = 200) {
        return NextResponse.json({ success: true, message, data }, { status });
    },

    error(message = 'Đã có lỗi xảy ra', status = 400) {
        return NextResponse.json({ success: false, message }, { status });
    },

    unauthorized(message = 'Không có quyền truy cập') {
        return NextResponse.json({ success: false, message }, { status: 401 });
    }
};
