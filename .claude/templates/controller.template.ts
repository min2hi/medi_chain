// @ts-nocheck — File này là TEMPLATE (code mẫu), không được biên dịch trực tiếp.
// Copy sang backend/src/ và thay thế placeholder trước khi dùng.
/**
 * TEMPLATE: MediChain Controller
 * ============================================================
 * HƯỚNG DẪN SỬ DỤNG:
 *   1. Copy file này → đổi tên thành `<tên>.controller.ts`
 *   2. Tìm-Thay toàn bộ "Example" → tên controller của bạn
 *   3. Tìm-Thay "ExampleService" → tên service tương ứng
 *   4. Xóa các comment hướng dẫn (dòng có tiền tố //*)
 *   5. Thêm/xóa methods theo nhu cầu
 * ============================================================
 * NGUYÊN TẮC BẮT BUỘC:
 *   ✅ Controller CHỈ xử lý HTTP: nhận req, gọi service, trả res
 *   ✅ Mọi method PHẢI có try/catch
 *   ✅ Dùng req.user.id (từ authMiddleware) — KHÔNG nhận userId từ req.body
 *   ✅ Response format chuẩn: { success, data? } hoặc { success, message }
 *   ❌ KHÔNG có business logic ở đây
 *   ❌ KHÔNG gọi Prisma trực tiếp
 *   ❌ KHÔNG gọi external API trực tiếp
 * ============================================================
 */

import { Request, Response } from 'express';
import { ExampleService } from '../services/example.service'; //* Đổi path sang service tương ứng

// ============================================================
// Controller Functions
// ============================================================

// ✅ CREATE
export const createExample = async (req: Request, res: Response) => {
  try {
    //* Lấy userId từ middleware (đã verify JWT) — KHÔNG từ req.body
    const userId = req.user!.id;

    //* Chỉ destructure các fields cần thiết từ body
    const { name, description } = req.body;

    const result = await ExampleService.create({ userId, name, description });

    //* Response chuẩn: 201 Created cho tạo mới thành công
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    res.status(400).json({ success: false, message });
  }
};

// ✅ GET ALL (của user đang đăng nhập)
export const getAllExamples = async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;

    const results = await ExampleService.getAll(userId);

    res.json({ success: true, data: results });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    res.status(500).json({ success: false, message });
  }
};

// ✅ GET BY ID
export const getExampleById = async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { id } = req.params; //* ID lấy từ URL params, không phải body

    const result = await ExampleService.getById(id, userId);

    res.json({ success: true, data: result });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    //* "không tìm thấy" → 404, các lỗi khác → 400
    const status = message.includes('Không tìm thấy') ? 404 : 400;
    res.status(status).json({ success: false, message });
  }
};

// ✅ UPDATE
export const updateExample = async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;
    const { name, description } = req.body;

    const result = await ExampleService.update(id, userId, { name, description });

    res.json({ success: true, data: result });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    const status = message.includes('Không tìm thấy') ? 404 : 400;
    res.status(status).json({ success: false, message });
  }
};

// ✅ DELETE
export const deleteExample = async (req: Request, res: Response) => {
  try {
    const userId = req.user!.id;
    const { id } = req.params;

    const result = await ExampleService.delete(id, userId);

    res.json({ success: true, data: result });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Lỗi không xác định';
    const status = message.includes('Không tìm thấy') ? 404 : 400;
    res.status(status).json({ success: false, message });
  }
};

//* ============================================================
//* Thêm các handler đặc thù bên dưới đây nếu cần
//* ============================================================
