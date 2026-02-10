import { PrismaClient } from '../generated/client/index.js';
import { PrismaPg } from '@prisma/adapter-pg';
declare const prisma: PrismaClient<{
    adapter: PrismaPg;
}, never, import("../generated/client/runtime/client.js").DefaultArgs>;
export default prisma;
