import prisma from '../config/prisma.js';
import { ConversationType, MessageRole } from '../generated/client/index.js';
import { MedicalSafetyService, UserMedicalProfile } from './medical-safety.service.js';

// Interface cho medical context (giữ nguyên để tương thích)
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
    private static GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
    private static GROQ_MODEL = "llama-3.3-70b-versatile";

    // Prompt Dược sĩ từ Frontend chuyển sang
    private static readonly PHARMACIST_PROMPT = `Bạn là Dược sĩ AI chuyên nghiệp của hệ thống MediChain.
Nhiệm vụ: Phân tích triệu chứng người dùng và đưa ra lời khuyên y tế sơ bộ.

Hướng dẫn trả lời:
1. Phân tích triệu chứng: Đánh giá mức độ nghiêm trọng dựa trên mô tả.
2. Gợi ý thuốc (Chỉ thuốc OTC - không kê đơn): Tên thuốc, công dụng, liều dùng tham khảo.
3. Lời khuyên chăm sóc: Chế độ ăn uống, nghỉ ngơi, vận động phù hợp.
4. CẢNH BÁO QUAN TRỌNG: Luôn nhắc người dùng đi khám bác sĩ ngay nếu triệu chứng kéo dài hoặc nghiêm trọng.

Định dạng trả lời: Markdown, sử dụng các gạch đầu dòng và in đậm để dễ đọc.
Giọng văn: Điềm đạm, chuyên nghiệp, thấu hiểu, ân cần.`;

    /**
     * Lấy medical context (Reuse cũ)
     */
    static async getMedicalContext(userId: string): Promise<MedicalContext> {
        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: {
                profile: true,
                records: { orderBy: { date: 'desc' }, take: 5 },
                medicines: {
                    where: { OR: [{ endDate: null }, { endDate: { gte: new Date() } }] },
                    orderBy: { startDate: 'desc' },
                },
                metrics: { orderBy: { date: 'desc' }, take: 10 },
            },
        });

        if (!user) throw new Error('User not found');

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
            recentRecords: user.records.map(r => ({
                title: r.title,
                diagnosis: r.diagnosis,
                treatment: r.treatment,
                date: r.date,
            })),
            currentMedicines: user.medicines.map(m => ({
                name: m.name,
                dosage: m.dosage,
                frequency: m.frequency,
            })),
            recentMetrics: user.metrics.map(m => ({
                type: m.type,
                value: m.value,
                unit: m.unit,
                date: m.date,
            })),
        };
    }

    /**
     * Gọi Groq API
     * FIX #3: Thêm AbortController 25s timeout để tránh request treo vô hạn
     * FIX #6: Validate content không rỗng để tránh hiển thị blank message
     */
    static async callGroq(systemPrompt: string, userMessage: string, history: any[] = [], options?: { jsonMode?: boolean }): Promise<{ content: string; usage: any }> {
        // Timeout 25s — đủ cho Groq phản hồi, trước khi Express/Render timeout ở 30s
        const GROQ_TIMEOUT_MS = 25_000;
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), GROQ_TIMEOUT_MS);

        try {
            const apiKey = process.env.GROQ_API_KEY;
            if (!apiKey) throw new Error('GROQ_API_KEY is missing');

            const messages = [
                { role: 'system', content: systemPrompt },
                ...history.map(h => ({ role: h.role.toLowerCase(), content: h.content })),
                { role: 'user', content: userMessage }
            ];

            const bodyPayload: any = {
                model: this.GROQ_MODEL,
                messages,
                temperature: 0.6,
                max_tokens: 1500,
            };

            if (options?.jsonMode) {
                bodyPayload.response_format = { type: 'json_object' };
            }

            const response = await fetch(this.GROQ_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${apiKey.replace(/['"]/g, '').trim()}`
                },
                body: JSON.stringify(bodyPayload),
                signal: controller.signal,
            });

            if (!response.ok) {
                const errBody = await response.json().catch(() => ({}));
                const errMsg = errBody.error?.message || `Groq API Error: ${response.status}`;
                // Rate limit — log rõ ràng để biết
                if (response.status === 429) {
                    console.warn('[Groq] Rate limited. Retry-After:', response.headers.get('retry-after'));
                    throw new Error('AI_RATE_LIMITED');
                }
                throw new Error(errMsg);
            }

            const data = await response.json();
            const content = data.choices[0]?.message?.content ?? '';

            // FIX #6: Validate content không được rỗng — Groq đôi khi trả empty khi bị filter
            if (!content || content.trim() === '') {
                console.error('[Groq] Received empty content response. Full data:', JSON.stringify(data));
                throw new Error('AI_EMPTY_RESPONSE');
            }

            return { content, usage: data.usage };
        } catch (error: any) {
            if (error.name === 'AbortError') {
                console.error('[Groq] Request timed out after 25s');
                throw new Error('AI_TIMEOUT');
            }
            console.error('[Groq] Call failed:', error.message);
            throw error;
        } finally {
            clearTimeout(timeoutId);
        }
    }

    /**
     * Chat với AI (Chatbot)
     */
    static async chat(userId: string, message: string, conversationId?: string, locale: string = 'vi') {
        let conversation;
        // 1. Find or Create Conversation
        if (conversationId) {
            conversation = await prisma.aIConversation.findFirst({
                where: { id: conversationId, userId, type: ConversationType.CHAT },
            });
            if (!conversation) throw new Error('Conversation not found');

            // Update lastMessageAt
            await prisma.aIConversation.update({
                where: { id: conversation.id },
                data: { lastMessageAt: new Date() }
            });
        } else {
            conversation = await prisma.aIConversation.create({
                data: {
                    userId,
                    type: ConversationType.CHAT,
                    title: message.substring(0, 50),
                    lastMessageAt: new Date(),
                },
            });
        }

        // 2. Build Context
        const context = await this.getMedicalContext(userId);
        const user = await prisma.user.findUnique({ where: { id: userId } });

        // Build patient profile summary for AI context
        const profileLines: string[] = [];
        if (context.profile.age) profileLines.push(`- Tuổi: ${context.profile.age}`);
        if (context.profile.gender) profileLines.push(`- Giới tính: ${context.profile.gender}`);
        if (context.profile.bloodType) profileLines.push(`- Nhóm máu: ${context.profile.bloodType}`);
        if (context.profile.weight && context.profile.height) profileLines.push(`- Cân nặng/Chiều cao: ${context.profile.weight}kg / ${context.profile.height}cm`);
        if (context.profile.bmi) profileLines.push(`- BMI: ${context.profile.bmi.toFixed(1)}`);
        if (context.profile.allergies) profileLines.push(`- ⚠️ DỊ ỨNG: ${context.profile.allergies}`);
        if (context.profile.chronicConditions) profileLines.push(`- 🔴 BỆNH NỀN: ${context.profile.chronicConditions}`);
        if (context.profile.isPregnant) profileLines.push(`- 🤰 Đang mang thai`);
        if (context.profile.isBreastfeeding) profileLines.push(`- 🍼 Đang cho con bú`);

        const currentMeds = context.currentMedicines.length > 0
            ? context.currentMedicines.map(m => `${m.name}${m.dosage ? ' ' + m.dosage : ''}${m.frequency ? ' (' + m.frequency + ')' : ''}`).join(', ')
            : 'Không';
        profileLines.push(`- Thuốc đang dùng: ${currentMeds}`);

        const recentRecordsSummary = context.recentRecords.length > 0
            ? context.recentRecords.slice(0, 3).map(r => `"${r.title}"${r.diagnosis ? ': ' + r.diagnosis : ''}`).join('; ')
            : 'Chưa có';

        const recentMetricsSummary = context.recentMetrics.length > 0
            ? context.recentMetrics.slice(0, 5).map(m => `${m.type}: ${m.value} ${m.unit}`).join(', ')
            : 'Chưa có';

        const profileText = profileLines.join('\n');
        const patientName = user?.name || 'bạn';

        let systemPrompt = `Bạn là **Dr. MediAI** — Bác sĩ ảo chuyên nghiệp của hệ thống MediChain.

## VAI TRÒ & DANH TÍNH
Bạn là một bác sĩ đa khoa ảo có kiến thức sâu rộng về y học, dược lý và chăm sóc sức khỏe. Bạn không phải là chatbot đơn thuần — bạn có hồ sơ sức khỏe đầy đủ của bệnh nhân và phải sử dụng dữ liệu này trong mọi phản hồi.

## HỒ SƠ BỆNH NHÂN ĐANG ĐIỀU TRỊ
Tên: ${patientName}
${profileText}
Bệnh án gần đây: ${recentRecordsSummary}
Chỉ số sức khỏe gần đây: ${recentMetricsSummary}

## NGUYÊN TẮC TRẢ LỜI BẮT BUỘC

### 1. PHONG CÁCH BÁC SĨ CHUYÊN NGHIỆP
- Luôn xưng hô thân thiện, ân cần như bác sĩ thật: "Chào ${patientName}", "Theo hồ sơ của bạn...", "Dựa trên các chỉ số gần đây..."
- Dùng ngôn ngữ dễ hiểu nhưng chính xác về mặt y khoa
- Tránh giọng máy móc, cứng nhắc — hãy thể hiện sự đồng cảm
- Khi chào hỏi lần đầu: tự giới thiệu ngắn gọn và hỏi thăm tình trạng sức khỏe

### 2. CÁ NHÂN HÓA THEO HỒ SƠ
- **LUÔN LUÔN** tham chiếu đến dữ liệu hồ sơ bệnh nhân khi trả lời
- Nếu bệnh nhân có dị ứng, nhắc đến trong lời khuyên liên quan
- Nếu có bệnh nền, điều chỉnh lời khuyên phù hợp
- Nếu đang dùng thuốc, cảnh báo tương tác nếu cần

### 3. CẤU TRÚC TRẢ LỜI (Tùy theo ngữ cảnh)
Với câu hỏi về triệu chứng:
- 🔍 **Đánh giá sơ bộ**: Nhận định về triệu chứng
- 📋 **Khuyến nghị**: Hành động cụ thể, rõ ràng
- ⚠️ **Dấu hiệu cần đi khám ngay**: Liệt kê red flags
- 💡 **Lời khuyên chăm sóc**: Chế độ sinh hoạt, ăn uống

Với câu hỏi thông thường về sức khỏe:
- Trả lời trực tiếp, súc tích, chính xác
- Liên hệ với hồ sơ bệnh nhân nếu phù hợp

### 4. GIỚI HẠN & AN TOÀN Y TẾ
- **KHÔNG** kê đơn thuốc kê đơn (prescription) — chỉ tư vấn OTC và lời khuyên chung
- **KHÔNG** chẩn đoán xác định bệnh — chỉ đánh giá sơ bộ
- **BẮT BUỘC** khuyên đi khám bác sĩ thực khi: triệu chứng nghiêm trọng, kéo dài >3-5 ngày, có red flags
- Khi gặp tình huống khẩn cấp (đau ngực, khó thở, mất ý thức...): yêu cầu gọi cấp cứu 115 NGAY

### 5. ĐỊNH DẠNG
- Sử dụng Markdown: **in đậm** cho điểm quan trọng, dùng bullet points, emoji phù hợp
- Độ dài phản hồi: Vừa phải — không quá ngắn (thiếu thông tin) cũng không quá dài (khó đọc)
- Kết thúc bằng câu hỏi follow-up hoặc lời mời hỏi thêm khi phù hợp

Hãy bắt đầu cuộc trò chuyện với tư cách Dr. MediAI.

${locale === 'en' ? 'CRITICAL REQUIREMENT: You MUST generate your ENTIRE response in ENGLISH language.' : 'YÊU CẦU QUAN TRỌNG: Bạn PHẢI tạo toàn bộ câu trả lời bằng TIẾNG VIỆT.'}`;

        // 3. Get History
        // FIX #5: Dùng orderBy asc trực tiếp + take âm để lấy 10 tin nhắn cuối ĐÚNG thứ tự
        // Anti-pattern cũ: orderBy desc → take 10 → reverse() — dễ gây sliding window bug
        const history = await prisma.aIMessage.findMany({
            where: { conversationId: conversation.id },
            orderBy: { createdAt: 'asc' },
            take: -10, // take âm: lấy 10 item CUỐI nhưng vẫn giữ thứ tự ASC (cũ → mới)
        });

        // 4. Save User Message
        await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.USER,
                content: message,
            }
        });

        // 5. Call AI
        const start = Date.now();
        const aiResponse = await this.callGroq(systemPrompt, message, history);
        const duration = Date.now() - start;

        // 6. Save AI Message with Tracking
        const aiMsg = await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.ASSISTANT,
                content: aiResponse.content,
                medicalContext: JSON.stringify(context),
                responseTimeMs: duration,
                promptTokens: aiResponse.usage?.prompt_tokens,
                completionTokens: aiResponse.usage?.completion_tokens,
                model: this.GROQ_MODEL
            }
        });

        // Update stats
        await prisma.aIConversation.update({
            where: { id: conversation.id },
            data: {
                totalMessages: { increment: 2 },
                totalTokens: { increment: (aiResponse.usage?.total_tokens || 0) }
            }
        });

        return { conversationId: conversation.id, message: aiMsg };
    }

    /**
     * Tư vấn thuốc (CONSULT type) - Production Grade
     */
    static async getMedicineRecommendation(userId: string, symptoms: string, conversationId?: string, locale: string = 'vi') {
        // 1. Find or Create Conversation
        let conversation;
        if (conversationId) {
            conversation = await prisma.aIConversation.findFirst({
                where: { id: conversationId, userId, type: ConversationType.CONSULT },
            });
            if (conversation) {
                await prisma.aIConversation.update({
                    where: { id: conversationId },
                    data: { lastMessageAt: new Date() }
                });
            }
        }

        if (!conversation) {
            conversation = await prisma.aIConversation.create({
                data: {
                    userId,
                    type: ConversationType.CONSULT,
                    title: "Tư vấn: " + symptoms.substring(0, 30),
                    lastMessageAt: new Date(),
                },
            });
        }

        // 2. Get Context & Map to Safety Profile
        const context = await this.getMedicalContext(userId);

        const safetyProfile: UserMedicalProfile = {
            allergies: context.profile.allergies,
            chronicConditions: context.profile.chronicConditions,
            currentMedicines: context.currentMedicines.map(m => m.name),
            isPregnant: context.profile.isPregnant || false,
            isBreastfeeding: context.profile.isBreastfeeding || false,
            age: context.profile.age,
            weight: context.profile.weight,
            gender: context.profile.gender
        };

        // 3. SAFETY CHECK (Logic cứng)
        const safetyCheck = MedicalSafetyService.performComprehensiveCheck(symptoms, safetyProfile);

        // 4. Save User Message
        await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.USER,
                content: symptoms,
                safetyCheckResult: JSON.stringify(safetyCheck)
            }
        });

        // 5. Handle Critical Alerts (Không gọi AI nếu nguy hiểm)
        if (safetyCheck.criticalAlerts.length > 0) {
            const criticalContentVi = `# ⚠️ CẢNH BÁO Y TẾ KHẨN CẤP\n\n${safetyCheck.criticalAlerts.join('\n\n')}\n\n**HÀNH ĐỘNG NGAY**: Vui lòng liên hệ bác sĩ hoặc cơ sở y tế gần nhất. Hệ thống từ chối đưa ra tư vấn thuốc trong trường hợp này để đảm bảo an toàn cho bạn.`;
            const criticalContentEn = `# ⚠️ EMERGENCY MEDICAL ALERT\n\n${safetyCheck.criticalAlerts.join('\n\n')}\n\n**ACT NOW**: Please contact a doctor or the nearest medical facility immediately. For your safety, the system declines to provide medication advice for this condition.`;
            
            const criticalContent = locale === 'en' ? criticalContentEn : criticalContentVi;

            await prisma.aIMessage.create({
                data: {
                    conversationId: conversation.id,
                    role: MessageRole.ASSISTANT,
                    content: criticalContent,
                    safetyCheckResult: JSON.stringify(safetyCheck),
                }
            });

            return { conversationId: conversation.id, message: { role: 'ASSISTANT', content: criticalContent }, safetyChecks: safetyCheck };
        }

        // 6. Build System Prompt for AI
        // QUAN TRỌNG: Yêu cầu AI trả về JSON structure cho thuốc
        let systemPrompt = `Bạn là Dược sĩ AI chuyên nghiệp của MediChain. 
Nhiệm vụ: Phân tích triệu chứng và đưa ra lời khuyên y tế an toàn.

Hồ sơ bệnh nhân:
- Tuổi: ${context.profile.age}
- Giới tính: ${context.profile.gender}
- Đang uống: ${context.currentMedicines.map(m => m.name).join(', ') || 'Không'}
- Bệnh nền: ${context.profile.chronicConditions || 'Không'}
- Dị ứng: ${context.profile.allergies || 'Không'}

YÊU CẦU ĐẦU RA (QUAN TRỌNG):
Bạn phải trả lời theo định dạng JSON sau đây (không markdown phức tạp, không giải thích thêm bên ngoài JSON):
{
  "content": "LỜI MỞ ĐẦU HOẶC GIỚI THIỆU NGẮN. Chỉ phân tích triệu chứng sơ bộ và hướng dẫn chăm sóc chung. TUYỆT ĐỐI KHÔNG liệt kê hay giải thích lại từng loại thuốc ở đây vì chúng đã được hiển thị trên giao diện ở phần bên dưới.",
  "recommendedMedicines": [
    {
      "name": "Tên thuốc",
      "ingredients": "Thành phần hoạt chất và hàm lượng (VD: Paracetamol 500mg, Phenylephrine 5mg)",
      "dosage": "Liều dùng cụ thể",
      "frequency": "Tần suất sử dụng",
      "instruction": "Lưu ý sử dụng (VD: Uống sau ăn 30p, tránh uống rượu)",
      "description": "Mô tả chi tiết về loại thuốc này, công dụng chính và đối tượng sử dụng",
      "mechanism": "Cơ chế tác động của thuốc đối với triệu chứng hiện tại",
      "comparison": "Tại sao chọn thuốc này thay vì các hoạt chất khác cùng loại",
      "safetyAnalysis": "Bác sĩ phân tích: Đối chiếu khắt khe với tiền sử bệnh nhân (dị ứng, bệnh lý nền, thuốc đang dùng) để khẳng định độ an toàn"
          }
        ]
}

Nguyên tắc an toàn dược lý (Của một bác sĩ):
1. KIỂM TRA ĐỘC TÍNH & XUNG ĐỘT: Tuyệt đối không gợi ý thuốc xung đột với thuốc hiện tại hoặc hoạt chất bệnh nhân từng dị ứng.
2. THÀNH PHẦN BẮT BUỘC: Trường 'ingredients' là thông tin sống còn. KHÔNG ĐƯỢC để trống hoặc ghi 'Chưa rõ'. Phải ghi chính xác tên hoạt chất và hàm lượng.
3. ĐA DẠNG HÓA PHƯƠNG ÁN: Hãy đưa ra ít nhất 2 phương án thuốc khác nhau (nếu an toàn) để bệnh nhân lựa chọn.
4. CHỈ ĐỊNH: Chỉ gợi ý thuốc OTC phù hợp tuổi và tình trạng sinh lý.
5. ƯU TIÊN: Đưa thuốc có hồ sơ an toàn tốt nhất lên đầu.
6. CẢNH BÁO: Bắt buộc yêu cầu đi khám nếu có dấu hiệu 'cờ đỏ' trong phần content.
7. QUY TẮC HIỂN THỊ: Phần 'content' CHỈ được chứa 1 đoạn tóm tắt ngắn (vài câu), KHÔNG sử dụng ký tự Markdown như ###, *, #. KHÔNG đánh số thứ tự thuốc.`;

        if (locale && locale.startsWith('en')) {
            systemPrompt += `\n\nCRITICAL INSTRUCTION: The user has set their language to ENGLISH. You MUST replay entirely in ENGLISH. All drug descriptions, dosages, ingredients, and the 'content' field in your JSON MUST be in professional English. Translate EVERYTHING into English, including the safety analysis.`;
        }

        // 7. Call AI
        const start = Date.now();
        const aiResponse = await this.callGroq(systemPrompt, symptoms);
        const duration = Date.now() - start;

        // 8. Parse AI Response (JSON)
        let finalContent = "";
        let recommendedMedicines = [];
        try {
            // Cố gắng parse JSON từ AI
            const jsonStart = aiResponse.content.indexOf('{');
            const jsonEnd = aiResponse.content.lastIndexOf('}');
            if (jsonStart !== -1 && jsonEnd !== -1) {
                const jsonStr = aiResponse.content.substring(jsonStart, jsonEnd + 1);
                const parsed = JSON.parse(jsonStr);
                finalContent = parsed.content;
                recommendedMedicines = parsed.recommendedMedicines || [];
            } else {
                finalContent = aiResponse.content; // Fallback nếu AI không trả về JSON
            }
        } catch (e) {
            console.error("Failed to parse AI JSON response", e);
            finalContent = aiResponse.content;
        }

        // 9. Append Safety Warnings to Content (nếu chưa có trong content AI)
        if (safetyCheck.warnings.length > 0) {
            finalContent += '\n\n---\n\n### ⚠️ Lưu ý quan trọng:\n\n' + safetyCheck.warnings.map(w => `- ${w}`).join('\n');
        }

        // 10. Save AI Message
        const aiMsg = await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.ASSISTANT,
                content: finalContent, // Chỉ lưu nội dung text hiển thị
                medicalContext: JSON.stringify({ ...safetyProfile, recommendedMedicines }), // Lưu metadata thuốc vào context
                safetyCheckResult: JSON.stringify(safetyCheck),
                responseTimeMs: duration,
                promptTokens: aiResponse.usage?.prompt_tokens,
                completionTokens: aiResponse.usage?.completion_tokens,
                model: this.GROQ_MODEL
            }
        });

        // 11. Update Stats
        await prisma.aIConversation.update({
            where: { id: conversation.id },
            data: {
                totalMessages: { increment: 2 },
                totalTokens: { increment: (aiResponse.usage?.total_tokens || 0) }
            }
        });

        return {
            conversationId: conversation.id,
            message: { role: 'ASSISTANT', content: finalContent },
            recommendedMedicines, // Trả về danh sách thuốc riêng để Frontend hiển thị Card
            safetyChecks: safetyCheck
        };
    }

    /**
     * =====================================================================
     * PHƯƠNG THỨC MỚI: Giải thích kết quả từ Recommendation Engine
     * =====================================================================
     * 
     * QUAN TRỌNG: Đây là phương thức AI ĐÚNG TRONG KIẾN TRÚC MỚI.
     * 
     * AI KHÔNG ĐƯỢC PHÉP:
     *   - Tự chọn thuốc
     *   - Bác bỏ kết quả của Engine
     *   - Thêm thuốc ngoài danh sách đã được Engine approve
     * 
     * AI CHỈ ĐƯỢC PHÉP:
     *   - Giải thích triệu chứng
     *   - Mô tả cách dùng từng thuốc trong danh sách
     *   - Gợi ý khi nào cần đi khám bác sĩ
     *   - Cung cấp thông tin chăm sóc sức khỏe hỗ trợ
     */
    static async getMedicineRecommendationWithContext(
        userId: string,
        symptoms: string,
        recommendationResult: {
            sessionId: string;
            rankedDrugs: any[];
            safetyWarnings: string[];
            profileSnapshot: any;
        },
        conversationId?: string,
        locale: string = 'vi'
    ) {
        // 1. Find or Create Conversation
        let conversation;
        if (conversationId) {
            conversation = await prisma.aIConversation.findFirst({
                where: { id: conversationId, userId, type: ConversationType.CONSULT },
            });
            if (conversation) {
                await prisma.aIConversation.update({
                    where: { id: conversationId },
                    data: { lastMessageAt: new Date() }
                });
            }
        }

        if (!conversation) {
            conversation = await prisma.aIConversation.create({
                data: {
                    userId,
                    type: ConversationType.CONSULT,
                    title: "Tư vấn: " + symptoms.substring(0, 30),
                    lastMessageAt: new Date(),
                },
            });
        }

        // 2. Lưu tin nhắn của user
        await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.USER,
                content: symptoms,
            }
        });

        const profile = recommendationResult.profileSnapshot;
        // TỐI ƯU HÓA: Chỉ phân tích liều lượng cho Top 5 Thuốc tốt nhất để tiết kiệm thời gian (Top-K Selection)
        const rankedDrugs = recommendationResult.rankedDrugs.slice(0, 5);

        // TỐI ƯU HÓA: Cắt gọt mỡ thừa văn bản, chỉ lấy 400 ký tự đầu của Chỉ Định (Context Truncation)
        const drugListForAI = rankedDrugs.map((drug) =>
            `ID: ${drug.drugId} - Thuốc: ${drug.drugName} (Hoạt chất: ${drug.genericName}) 
   - Thành phần: ${drug.ingredients}
   - Chỉ định/Liều chuẩn: ${(drug.indications || '').substring(0, 400)}...`
        ).join('\n\n');

        let systemPrompt = `Bạn là Dược sĩ AI của MediChain.
Hệ thống Recommendation Engine đã chọn các thuốc AN TOÀN cho bệnh nhân. Nhiệm vụ của bạn:
1. Đưa ra một đoạn Nhận định sơ bộ.
2. Dựa vào Cân nặng, Tuổi và Hồ sơ, tính toán Liều lượng CỤ THỂ (Dosage, Frequency, Instruction) cho TỪNG loại thuốc.

THÔNG TIN BỆNH NHÂN:
- Tuổi: ${profile.age || 'Chưa cập nhật'}
- Cân nặng: ${profile.weight ? profile.weight + ' kg' : 'Chưa cập nhật'}
- Giới tính: ${profile.gender || 'Chưa cập nhật'}
- Dị ứng: ${profile.allergies || 'Không'}
- Bệnh nền: ${profile.chronicConditions || 'Không'}
- Thai kỳ/Cho con bú: ${profile.isPregnant ? 'Có mang thai' : profile.isBreastfeeding ? 'Đang cho con bú' : 'Không'}

DANH SÁCH THUỐC ĐÃ CHỌN:
${drugListForAI}

QUY TẮC JSON BẮT BUỘC (TUYỆT ĐỐI KHÔNG giải thích thêm ngoài JSON):
Trình bày kết quả CHỈ bằng đúng 1 file JSON có cấu trúc sau:
{
  "content": "2-3 câu khuyên chăm sóc tại nhà, nhận định sơ bộ triệu chứng.",
  "dosages": {
    "ID_của_thuốc": {
      "dosage": "1 viên (VD)",
      "frequency": "2 lần/ngày (VD)",
      "instruction": "Sau ăn no 30 phút (VD)"
    }
  }
}`;

}

${locale === 'en' ? 'CRITICAL REQUIREMENT: YOU MUST GENERATE ALL JSON STRING VALUES IN ENGLISH (e.g. content, dosage, frequency, instruction MUST be translated to English). Keep the JSON KEYS exactly as defined above.' : 'YÊU CẦU QUAN TRỌNG: TẤT CẢ GIÁ TRỊ TRONG JSON PHẢI LÀ TIẾNG VIỆT.'}`;

        // 4. Call AI
        const start = Date.now();
        // Cần đảm bảo Groq trả JSON, ta dùng prompt gắt gao. TỐI ƯU HÓA: jsonMode true (JSON Mode Native)
        const aiResponse = await this.callGroq(
            systemPrompt,
            locale === 'en' ? `Patient symptoms: "${symptoms}"\n\nPlease output the JSON dosage instructions for the above medicines in English.` : `Triệu chứng bệnh nhân: "${symptoms}"\n\nHãy xuất JSON hướng dẫn liều lượng cho các thuốc trên.`,
            [],
            { jsonMode: true }
        );
        const duration = Date.now() - start;

        // 5. Parse JSON
        let finalContent = "";
        let dosages = {};
        try {
            const jsonStart = aiResponse.content.indexOf('{');
            const jsonEnd = aiResponse.content.lastIndexOf('}');
            if (jsonStart !== -1 && jsonEnd !== -1) {
                const jsonStr = aiResponse.content.substring(jsonStart, jsonEnd + 1);
                const parsed = JSON.parse(jsonStr);
                finalContent = parsed.content || (locale === 'en' ? "Sorry, could not extract advice." : "Xin lỗi, không thể trích xuất lời khuyên.");
                dosages = parsed.dosages || {};
            } else {
                finalContent = aiResponse.content;
            }
        } catch (e) {
            console.error("Failed to parse AI JSON response for dosages", e);
            finalContent = aiResponse.content;
        }

        // 6. Append safety warnings nếu có
        if (recommendationResult.safetyWarnings.length > 0) {
            finalContent += locale === 'en' 
                ? '\n\n---\n\n### 🛡️ Information from Safety System:\n\n' + recommendationResult.safetyWarnings.map(w => `- ${w}`).join('\n')
                : '\n\n---\n\n### 🛡️ Thông tin từ Hệ thống An toàn:\n\n' + recommendationResult.safetyWarnings.map(w => `- ${w}`).join('\n');
        }

        // 7. Lưu AI message
        const aiMsg = await prisma.aIMessage.create({
            data: {
                conversationId: conversation.id,
                role: MessageRole.ASSISTANT,
                content: finalContent,
                medicalContext: JSON.stringify({
                    sessionId: recommendationResult.sessionId,
                    rankedDrugs: rankedDrugs.map(d => ({ name: d.drugName, score: d.finalScore })),
                }),
                responseTimeMs: duration,
                promptTokens: aiResponse.usage?.prompt_tokens,
                completionTokens: aiResponse.usage?.completion_tokens,
                model: this.GROQ_MODEL,
            }
        });

        // 8. Update conversation stats
        await prisma.aIConversation.update({
            where: { id: conversation.id },
            data: {
                totalMessages: { increment: 2 },
                totalTokens: { increment: (aiResponse.usage?.total_tokens || 0) }
            }
        });

        return {
            conversationId: conversation.id,
            message: { role: 'ASSISTANT', content: finalContent },
            dosages
        };
    }

    static async getConversations(userId: string, type?: ConversationType) {
        return prisma.aIConversation.findMany({
            where: {
                userId,
                isArchived: false,
                ...(type ? { type } : {})
            },
            orderBy: { lastMessageAt: 'desc' },
            include: {
                messages: {
                    take: 1,
                    orderBy: { createdAt: 'desc' }
                }
            }
        });
    }

    static async getMessages(userId: string, conversationId: string) {
        const conv = await prisma.aIConversation.findFirst({
            where: { id: conversationId, userId },
            include: { messages: { orderBy: { createdAt: 'asc' } } }
        });
        if (!conv) throw new Error('Conversation not found');
        return conv.messages;
    }

    static async deleteConversation(userId: string, conversationId: string) {
        return await prisma.aIConversation.deleteMany({
            where: { id: conversationId, userId }
        });
    }

    static async analyzeMedicalData(userId: string): Promise<string> {
        const context = await this.getMedicalContext(userId);
        const systemPrompt = "Bạn là chuyên gia phân tích dữ liệu y tế.";
        const userPrompt = `Hãy phân tích hồ sơ sau và đưa ra đánh giá sức khỏe tổng quát: ${JSON.stringify(context)}`;
        const res = await this.callGroq(systemPrompt, userPrompt);
        return res.content;
    }
}
