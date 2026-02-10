import prisma from './src/config/prisma.js';

async function updateProfile() {
    const user = await prisma.user.findFirst({
        where: { OR: [{ name: 'Nguyễn Minh Huy' }, { email: 'minhhuy@gmail.com' }] }
    });

    if (user) {
        console.log(`Updating profile for ${user.email}...`);
        await prisma.profile.upsert({
            where: { userId: user.id },
            update: {
                birthday: new Date('1980-05-15'), // > 40 years old
                gender: 'male',
                weight: 85, // BMI > 25 (High)
                height: 170,
                allergies: 'Bụi phấn, Phấn hoa'
            },
            create: {
                userId: user.id,
                birthday: new Date('1980-05-15'),
                gender: 'male',
                weight: 85,
                height: 170,
                allergies: 'Bụi phấn, Phấn hoa'
            }
        });
        console.log('✅ Profile updated!');
    } else {
        console.log('❌ User not found');
    }
}

updateProfile();
