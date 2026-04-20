import prisma from './src/config/prisma.js';
import bcrypt from 'bcryptjs';



async function main() {
    const hashedPassword = await bcrypt.hash('admin123', 10);
    await prisma.user.upsert({
        where: { email: 'admin@medichain.com' },
        update: { role: 'ADMIN', password: hashedPassword },
        create: { name: 'Admin', email: 'admin@medichain.com', password: hashedPassword, role: 'ADMIN' }
    });
    console.log('Admin user created/updated successfully: admin@medichain.com / admin123');
}

main().catch(console.error).finally(() => prisma.$disconnect());
