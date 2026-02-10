import prisma from '../config/prisma.js';

// Interface cho medical context
interface MedicalContext {
    profile: {
        age: number | null;
        gender: string | null;
        bloodType: string | null;
        allergies: string | null;
        weight: number | null;
        height: number | null;
        bmi: number | null;
        chronicConditions: string | null;
        isPregnant: boolean | null;
        isBreastfeeding: boolean | null;
    };
    recentRecords: Array<{
        title: string;
        diagnosis: string | null;
        treatment: string | null;
        date: Date;
    }>;
    currentMedicines: Array<{
        name: string;
        dosage: string | null;
        frequency: string | null;
    }>;
    recentMetrics: Array<{
        type: string;
        value: number;
        unit: string;
        date: Date;
    }>;
}

export class AIService {
    /**
     * Lấy medical context của user để làm RAG
     */
    static async getMedicalContext(userId: string): Promise<MedicalContext> {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                profile: true,
                records: {
                    orderBy: { date: 'desc' },
                    take: 5,
                },
                medicines: {
                    where: {
                        OR: [
                            { endDate: null },
                            { endDate: { gte: new Date() } },
                        ],
                    },
                    orderBy: { startDate: 'desc' },
                },
                metrics: {
                    orderBy: { date: 'desc' },
                    take: 10,
                },
            },
        });

        if (!user) {
            throw new Error('User not found');
        }

        const age = user.profile?.birthday
            ? Math.floor((new Date().getTime() - new Date(user.profile.birthday).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
            : null;

        const bmi = user.profile?.weight && user.profile?.height
            ? user.profile.weight / Math.pow(user.profile.height / 100, 2)
            : null;

        return {
            profile: {
                age,
                gender: user.profile?.gender || null,
                bloodType: user.profile?.bloodType || null,
                allergies: user.profile?.allergies || null,
                weight: user.profile?.weight || null,
                height: user.profile?.height || null,
                bmi,
                chronicConditions: user.profile?.chronicConditions || null,
                isPregnant: user.profile?.isPregnant || null,
                isBreastfeeding: user.profile?.isBreastfeeding || null,
            },
            recentRecords: user.records.map((r) => ({
                title: r.title,
                diagnosis: r.diagnosis,
                treatment: r.treatment,
                date: r.date,
            })),
            currentMedicines: user.medicines.map((m) => ({
                name: m.name,
                dosage: m.dosage,
                frequency: m.frequency,
            })),
            recentMetrics: user.metrics.map((m) => ({
                type: m.type,
                value: m.value,
                unit: m.unit,
                date: m.date,
            })),
        };
    }

    /**
     * Tạo system prompt cho AI với medical context
     */
    static createSystemPrompt(context: MedicalContext, userName: string): string {
        const { profile, recentRecords, currentMedicines, recentMetrics } = context;

        let prompt = `Bạn là Trợ lý Y tế MediChain - một AI chuyên nghiệp, thân thiện và đáng tin cậy.

THÔNG TIN NGƯỜI DÙNG:
- Tên: ${userName}`;

        if (profile.age) {
            prompt += `\n- Tuổi: ${profile.age} tuổi`;
        }
        if (profile.gender) {
            prompt += `\n- Giới tính: ${profile.gender}`;
        }
        if (profile.bloodType) {
            prompt += `\n- Nhóm máu: ${profile.bloodType}`;
        }
        if (profile.weight && profile.height) {
            prompt += `\n- Cân nặng: ${profile.weight}kg, Chiều cao: ${profile.height}cm`;
            if (profile.bmi) {
                prompt += ` (BMI: ${profile.bmi.toFixed(1)})`;
            }
        }
        if (profile.allergies) {
            prompt += `\n- ⚠️ DỊ ỨNG: ${profile.allergies}`;
        }

        if (currentMedicines.length > 0) {
            prompt += `\n\nTHUỐC ĐANG DÙNG:`;
            currentMedicines.forEach((med) => {
                prompt += `\n- ${med.name}`;
                if (med.dosage) prompt += ` (${med.dosage})`;
                if (med.frequency) prompt += ` - ${med.frequency}`;
            });
        }

        if (recentRecords.length > 0) {
            prompt += `\n\nHỒ SƠ BỆNH ÁN GẦN ĐÂY:`;
            recentRecords.slice(0, 3).forEach((record) => {
                prompt += `\n- ${record.title}`;
                if (record.diagnosis) prompt += ` | Chẩn đoán: ${record.diagnosis}`;
                if (record.treatment) prompt += ` | Điều trị: ${record.treatment}`;
            });
        }

        if (recentMetrics.length > 0) {
            prompt += `\n\nCHỈ SỐ SỨC KHỎE GẦN NHẤT:`;
            const latestMetrics = recentMetrics.slice(0, 5);
            latestMetrics.forEach((metric) => {
                const date = new Date(metric.date).toLocaleDateString('vi-VN');
                prompt += `\n- ${metric.type}: ${metric.value} ${metric.unit} (${date})`;
            });
        }

        prompt += `\n\nQUY TẮC TƯ VẤN:
1. **An toàn tuyệt đối**: Luôn ưu tiên sự an toàn của người dùng.
2. **Dựa trên dữ liệu**: Chỉ tư vấn dựa trên thông tin y tế đã cung cấp ở trên.
3. **Cảnh báo dị ứng**: Nếu câu hỏi liên quan đến thuốc và người dùng có tiền sử dị ứng, PHẢI cảnh báo rõ ràng.
4. **Khẩn cấp**: Nếu phát hiện dấu hiệu nguy hiểm (đau ngực, khó thở, chảy máu nhiều, v.v.), yêu cầu GỌI CẤP CỨU 115 NGAY.
5. **Không thay thế bác sĩ**: Luôn nhắc nhở "Đây chỉ là tham khảo, hãy hỏi ý kiến bác sĩ chuyên khoa".
6. **Không đoán mò**: Nếu không chắc chắn, hãy thừa nhận và khuyên người dùng đi khám.
7. **Ngôn ngữ**: Sử dụng tiếng Việt thân thiện, dễ hiểu, tránh thuật ngữ y học phức tạp.

Hãy trả lời câu hỏi của người dùng một cách chuyên nghiệp, thân thiện và có trách nhiệm.`;

        return prompt;
    }

    /**
     * Gọi AI API sử dụng Google Gemini
     */
    static async callAI(systemPrompt: string, userMessage: string): Promise<string> {
        try {
            // Import dộng để tránh lỗi nếu chưa cài package (nhưng đã cài rồi)
            const { GoogleGenerativeAI } = await import('@google/generative-ai');

            const apiKey = process.env.GEMINI_API_KEY;
            if (!apiKey) {
                throw new Error('Dịch vụ AI hiện không khả dụng do thiếu cấu hình API Key.');
            }

            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
            console.log("[AIService] Initialized model: gemini-1.5-flash");

            const chat = model.startChat({
                history: [
                    {
                        role: 'user',
                        parts: [{ text: systemPrompt }],
                    },
                    {
                        role: 'model',
                        parts: [{ text: 'Đã rõ. Tôi sẽ đóng vai trò là Trợ lý Y tế MediChain và tuân thủ mọi quy tắc an toàn cũng như chuyên môn mà bạn đã đề ra. Tôi đã sẵn sàng hỗ trợ người dùng dựa trên hồ sơ y tế được cung cấp.' }],
                    }
                ],
                generationConfig: {
                    maxOutputTokens: 1000,
                },
            });

            const result = await chat.sendMessage(userMessage);
            const response = await result.response;
            return response.text();

        } catch (error: any) {
            console.error('Error calling Gemini AI:', error);
            throw new Error(`Lỗi kết nối AI: ${error.message}`);
        }
    }

    /**
     * Chat với AI (main function)
     */
    static async chat(userId: string, message: string, conversationId?: string) {
        // 1. Lấy hoặc tạo conversation
        let conversation;
        if (conversationId) {
            conversation = await prisma.aIConversation.findFirst({
                where: { id: conversationId, userId },
            });
            if (!conversation) {
                throw new Error('Conversation not found');
            }
        } else {
            conversation = await prisma.aIConversation.create({
                data: {
                    userId,
                    title: message.substring(0, 50) + (message.length > 50 ? '...' : ''),
                },
            });
        }

        // 2. Lưu user message
        await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: 'USER',
                content: message,
            },
        });

        // 3. Lấy medical context
        const context = await this.getMedicalContext(userId);

        // 4. Lấy user name
        const user = await prisma.user.findUnique({ where: { id: userId } });
        const userName = user?.name || 'Bạn';

        // 5. Tạo system prompt
        const systemPrompt = this.createSystemPrompt(context, userName);

        // 6. Gọi AI
        const aiResponse = await this.callAI(systemPrompt, message);

        // 7. Lưu AI response
        const aiMessage = await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: 'ASSISTANT',
                content: aiResponse,
                contextUsed: JSON.stringify(context),
            },
        });

        return {
            conversationId: conversation.id,
            message: aiMessage,
        };
    }

    /**
     * Lấy lịch sử conversation
     */
    static async getConversations(userId: string) {
        return await prisma.aIConversation.findMany({
            where: { userId },
            include: {
                messages: {
                    orderBy: { createdAt: 'asc' },
                    take: 1, // Chỉ lấy message đầu tiên để hiển thị preview
                },
            },
            orderBy: { updatedAt: 'desc' },
        });
    }

    /**
     * Lấy messages trong conversation
     */
    static async getMessages(userId: string, conversationId: string) {
        const conversation = await prisma.aIConversation.findFirst({
            where: { id: conversationId, userId },
            include: {
                messages: {
                    orderBy: { createdAt: 'asc' },
                },
            },
        });

        if (!conversation) {
            throw new Error('Conversation not found');
        }

        return conversation.messages;
    }

    /**
     * Xóa conversation
     */
    static async deleteConversation(userId: string, conversationId: string) {
        const conversation = await prisma.aIConversation.findFirst({
            where: { id: conversationId, userId },
        });

        if (!conversation) {
            throw new Error('Conversation not found');
        }

        return await prisma.aIConversation.delete({
            where: { id: conversationId },
        });
    }

    /**
     * Phân tích y tế bằng AI (cho nút "Phân tích bởi AI")
     */
    static async analyzeMedicalData(userId: string): Promise<string> {
        const context = await this.getMedicalContext(userId);
        const user = await prisma.user.findUnique({ where: { id: userId } });
        const userName = user?.name || 'Bạn';

        const analysisPrompt = `Dựa trên dữ liệu y tế của ${userName}, hãy phân tích tổng quan tình trạng sức khỏe:

${JSON.stringify(context, null, 2)}

Hãy đưa ra:
1. Đánh giá tổng quan
2. Các chỉ số đáng chú ý
3. Khuyến nghị cải thiện sức khỏe
4. Lưu ý cần theo dõi

Trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu.`;

        return await this.callAI('Bạn là chuyên gia phân tích y tế.', analysisPrompt);
    }

    /**
     * Tư vấn thuốc dựa trên triệu chứng và hồ sơ y tế (Prompt Engineering nâng cao)
     */
    /**
     * Tư vấn thuốc dựa trên triệu chứng và hồ sơ y tế (Prompt Engineering nâng cao + Google Search Grounding)
     */
    static async getMedicineRecommendation(userId: string, symptoms: string): Promise<any> {
        console.log(`[AIService] CONSULT start: User=${userId}, Symptoms="${symptoms}"`);
        const { GoogleGenerativeAI } = await import('@google/generative-ai');
        const apiKey = process.env.GEMINI_API_KEY;

        if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY_HERE') {
            console.warn("[AIService] Missing API Key");
            return {
                diagnosis_support: "Hệ thống AI chưa được cấu hình API Key.",
                lifestyle_advice: [],
                suggested_medicines: [],
                warning: "Vui lòng cấu hình GEMINI_API_KEY trong .env"
            };
        }

        try {
            const context = await this.getMedicalContext(userId);
            const user = await prisma.user.findUnique({ where: { id: userId } });

            const userProfile = {
                name: user?.name || 'Người dùng',
                allergies: context.profile.allergies || 'Không rõ',
                conditions: context.profile.chronicConditions || 'Không rõ',
            };

            const prompt = `Phân tích triệu chứng sau cho bệnh nhân ${userProfile.name} (Dị ứng: ${userProfile.allergies}, Bệnh nền: ${userProfile.conditions}).
            Triệu chứng: ${symptoms}
            
            Hãy trả về định dạng JSON DUY NHẤT (không có text khác):
            {
              "diagnosis_support": "...",
              "lifestyle_advice": ["...", "..."],
              "suggested_medicines": [{"name": "...", "reason": "...", "safety_check": "..."}],
              "warning": "..."
            }`;

            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
            console.log("[AIService] Consult Initialized model: gemini-1.5-flash");

            console.log("[AIService] Calling Gemini...");
            const result = await model.generateContent(prompt);
            const text = result.response.text();
            console.log("[AIService] Gemini response received:", text.substring(0, 100) + "...");

            const jsonMatch = text.match(/\{[\s\S]*\}/);
            const data = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(text);
            return data;
        } catch (error: any) {
            console.error("[AIService] Error:", error);
            return {
                diagnosis_support: "Có lỗi khi kết nối với trí tuệ nhân tạo.",
                lifestyle_advice: ["Nghỉ ngơi và theo dõi thêm"],
                suggested_medicines: [],
                warning: `Chi tiết: ${error.message}`
            };
        }
    }
}
