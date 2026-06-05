import { PrismaClient } from '../../src/generated/client/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

// Use standard connection from env
let connectionString = process.env.DATABASE_URL!;

const isSSL = connectionString.includes('sslmode=require');
const pool = new pg.Pool({
    connectionString,
    ssl: isSSL ? { rejectUnauthorized: false } : undefined,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Querying all active SafetyKeywords...');
  const keywords = await prisma.safetyKeyword.findMany({
    where: {
      isActive: true
    }
  });

  console.log(`Found ${keywords.length} active keywords:`);
  for (const kw of keywords) {
    console.log(`- ID: ${kw.id}, GroupId: ${kw.groupId}, GroupLabel: ${kw.groupLabel}, Keyword: ${kw.keyword}`);
  }
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
