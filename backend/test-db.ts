import { PrismaClient } from '@prisma/client';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(__dirname, '.env') });

async function main() {
  console.log('Testing DB connection...');
  console.log('DATABASE_URL from env:', process.env.DATABASE_URL);
  
  const prisma = new PrismaClient({
    datasources: {
      db: {
        url: process.env.DATABASE_URL
      }
    }
  } as any);

  try {
    await prisma.$connect();
    console.log('✅ Connection successful!');
    const users = await prisma.user.count();
    console.log('Users count:', users);
  } catch (e) {
    console.error('❌ Connection failed:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
