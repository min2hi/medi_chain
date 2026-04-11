import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import aiRoutes from './routes/ai.routes.js';
import recommendationRoutes from './routes/recommendation.routes.js';
import sharingRoutes from './routes/sharing.routes.js';
import prisma from './config/prisma.js';
import { startScheduler } from './cron/scheduler.js';
import { EmailService } from './services/email.service.js';

dotenv.config();

// ─── Fail-Fast: Kiểm tra biến môi trường bắt buộc ───
// Phải chạy TRƯỚC khi setup bất kỳ middleware nào
if (!process.env.JWT_SECRET) {
    console.error('❌ FATAL: JWT_SECRET không được set trong .env. Server từ chối khởi động.');
    process.exit(1);
}
if (!process.env.GEMINI_API_KEY) {
    console.warn('⚠️  GEMINI_API_KEY chưa được set — Vector Search sẽ fallback sang Keyword Matching.');
}

const app = express();
const PORT = Number(process.env.PORT) || 5000;

// ─── Security: Helmet (15 HTTP security headers) ───
app.use(helmet());

// ─── Security: CORS — Giới hạn theo FRONTEND_URL ───
const allowedOrigins = (process.env.FRONTEND_URL || 'http://localhost:3000')
    .split(',')
    .map(o => o.trim());

app.use(cors({
    origin: (origin, callback) => {
        // Cho phép không có origin (mobile app, Postman, server-to-server)
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error(`CORS: Origin '${origin}' không được phép`));
        }
    },
    credentials: true,
}));

// ─── Security: Rate Limiting ───
// Auth routes: 20 lần / 15 phút (chống brute-force login)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Quá nhiều yêu cầu. Vui lòng thử lại sau 15 phút.' },
});

// API chung: 120 lần / phút (chống spam)
const apiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 120,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Quá nhiều yêu cầu. Vui lòng thử lại sau.' },
});

app.use(express.json({ limit: '1mb' })); // Giới hạn body size

app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// ─── Security: Apply Rate Limiters ───
app.use('/api/auth', authLimiter);  // Chặn brute-force login
app.use('/api', apiLimiter);        // Chặn spam toàn bộ API

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/recommendation', recommendationRoutes);
app.use('/api/sharing', sharingRoutes);

// Base route
app.get('/', (req, res) => {
    res.send('MediChain API is running...');
});


app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server is running on port ${PORT} (all interfaces - 0.0.0.0)`);
    console.log(`📱 Android Emulator: http://10.0.2.2:${PORT}/api`);
    console.log(`🌐 Web/Desktop: http://localhost:${PORT}/api`);
    console.log(`📂 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔗 Database: ${process.env.DATABASE_URL?.split('@')[1] ? '...hidden...@' + process.env.DATABASE_URL.split('@')[1] : 'Not Set'}`);

    void (async () => {
        try {
            await prisma.$connect();
            console.log('✅ Database connected effectively');

            // Kiểm tra SMTP connection sau khi DB sẵn sàng
            await EmailService.verifyConnection();

            // Khởi động Job Scheduler sau khi DB đã sẵn sàng
            startScheduler();
        } catch (error) {
            console.error('❌ Database connection failed:', error);
        }
    })();
});
