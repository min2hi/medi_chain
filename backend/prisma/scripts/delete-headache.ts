import { PrismaClient } from '../../src/generated/client/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

let connectionString = process.env.DATABASE_URL!;
const isSSL = connectionString.includes('sslmode=require');
const pool = new pg.Pool({
    connectionString,
    ssl: isSSL ? { rejectUnauthorized: false } : undefined,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Deactivating "đau đầu" under groupId "general"...');
  const result = await prisma.safetyKeyword.updateMany({
    where: {
      groupId: 'general',
      keyword: 'đau đầu',
    },
    data: {
      isActive: false,
      reviewStatus: 'REJECTED',
      changeNote: 'Deactivated because generic "đau đầu" should not trigger emergency 115.',
    }
  });
  console.log(`Deactivated ${result.count} keywords.`);
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
