import { PrismaClient } from '../generated/client/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const connectionString = process.env.DATABASE_URL;

// Neon.tech (cloud DB) yêu cầu SSL — detect qua ?sslmode=require trong URL
const isSSL = connectionString?.includes('sslmode=require');

const pool = new pg.Pool({
    connectionString,
    ssl: isSSL ? { rejectUnauthorized: false } : undefined,
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

export default prisma;

