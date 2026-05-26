// @ts-nocheck — File này là TEMPLATE (code mẫu), không được biên dịch trực tiếp.
// Copy sang backend/src/ và thay thế placeholder trước khi dùng.
/**
 * TEMPLATE: MediChain Service
 * ============================================================
 * HƯỚNG DẪN SỬ DỤNG:
 *   1. Copy file này → đổi tên thành `<tên>.service.ts`
 *   2. Tìm-Thay toàn bộ "Example" → tên service của bạn (VD: "Medicine", "Appointment")
 *   3. Tìm-Thay "example" → tên bảng Prisma tương ứng (VD: "medicine", "appointment")
 *   4. Xóa các comment hướng dẫn (dòng có tiền tố //*)
 *   5. Xóa các method không cần thiết
 * ============================================================
 * NGUYÊN TẮC:
 *   ✅ Mọi business logic nằm ở đây, KHÔNG nằm trong Controller
 *   ✅ Dùng static async methods
 *   ✅ Validate input ở đầu mỗi method trước khi query DB
 *   ✅ Throw Error với message rõ ràng — Controller sẽ catch
 *   ✅ Dùng Prisma select để chỉ lấy fields cần thiết
 *   ❌ KHÔNG gọi external API trực tiếp mà không có error handling
 *   ❌ KHÔNG để business logic nào trong Controller
 * ============================================================
 */

import prisma from '../config/prisma';
//* Thêm import khác nếu cần: import { SomeOtherService } from './some-other.service';

// ============================================================
// Types & DTOs
// ============================================================

//* Định nghĩa DTO (Data Transfer Object) cho input của service.
//* Tách rõ ràng: CreateDto cho tạo mới, UpdateDto cho cập nhật.
export interface CreateExampleDto {
  userId: string;       //* Luôn nhận userId từ Controller (lấy từ req.user.id)
  name: string;
  description?: string; //* Optional fields dùng `?`
}

export interface UpdateExampleDto {
  name?: string;        //* Tất cả fields trong Update đều optional
  description?: string;
}

// ============================================================
// Service Class
// ============================================================

export class ExampleService {

  // ✅ Pattern chuẩn: CREATE
  static async create(dto: CreateExampleDto) {
    //* Bước 1: Validate input bắt buộc
    if (!dto.userId) throw new Error('userId là bắt buộc');
    if (!dto.name || dto.name.trim() === '') throw new Error('Tên không được để trống');

    //* Bước 2: Kiểm tra xem record đã tồn tại chưa (nếu cần)
    // const existing = await prisma.example.findFirst({
    //   where: { userId: dto.userId, name: dto.name },
    // });
    // if (existing) throw new Error('Dữ liệu này đã tồn tại');

    //* Bước 3: Create record trong DB
    //* QUAN TRỌNG: Dùng `select` để chỉ lấy fields cần trả về, không lấy thừa
    const record = await prisma.example.create({
      data: {
        userId: dto.userId,
        name: dto.name.trim(),
        description: dto.description,
      },
      select: {
        id: true,
        name: true,
        description: true,
        createdAt: true,
        //* KHÔNG select password, secretKey hay bất kỳ sensitive field nào
      },
    });

    return record;
  }

  // ✅ Pattern chuẩn: GET ALL (của một user)
  static async getAll(userId: string) {
    if (!userId) throw new Error('userId là bắt buộc');

    const records = await prisma.example.findMany({
      where: { userId },
      select: {
        id: true,
        name: true,
        description: true,
        createdAt: true,
        updatedAt: true,
      },
      orderBy: { createdAt: 'desc' }, //* Mặc định sort theo mới nhất
    });

    return records;
  }

  // ✅ Pattern chuẩn: GET BY ID (với ownership check)
  static async getById(id: string, userId: string) {
    if (!id) throw new Error('id là bắt buộc');
    if (!userId) throw new Error('userId là bắt buộc');

    const record = await prisma.example.findFirst({
      where: {
        id,
        userId, //* ⚠️ LUÔN filter theo userId để ngăn truy cập chéo (IDOR vulnerability)
      },
      select: {
        id: true,
        name: true,
        description: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    //* Trả về null an toàn nếu không tìm thấy — Controller sẽ xử lý 404
    if (!record) throw new Error('Không tìm thấy hoặc bạn không có quyền truy cập');

    return record;
  }

  // ✅ Pattern chuẩn: UPDATE (với ownership check)
  static async update(id: string, userId: string, dto: UpdateExampleDto) {
    if (!id) throw new Error('id là bắt buộc');

    //* Bước 1: Verify ownership trước khi update
    const existing = await prisma.example.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new Error('Không tìm thấy hoặc bạn không có quyền chỉnh sửa');

    //* Bước 2: Build update data (chỉ update fields được truyền vào)
    const updateData: Record<string, unknown> = {};
    if (dto.name !== undefined) updateData.name = dto.name.trim();
    if (dto.description !== undefined) updateData.description = dto.description;

    //* Bước 3: Thực hiện update
    const updated = await prisma.example.update({
      where: { id },
      data: updateData,
      select: {
        id: true,
        name: true,
        description: true,
        updatedAt: true,
      },
    });

    return updated;
  }

  // ✅ Pattern chuẩn: DELETE (với ownership check)
  static async delete(id: string, userId: string) {
    if (!id) throw new Error('id là bắt buộc');

    //* Verify ownership trước khi xóa
    const existing = await prisma.example.findFirst({
      where: { id, userId },
    });
    if (!existing) throw new Error('Không tìm thấy hoặc bạn không có quyền xóa');

    await prisma.example.delete({ where: { id } });

    return { deleted: true, id };
  }

  //* ============================================================
  //* Thêm các method nghiệp vụ đặc thù bên dưới đây
  //* Ví dụ: search, filter, aggregate, gọi external API...
  //* ============================================================
}
