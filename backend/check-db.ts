import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const transactions = await prisma.transaction.findMany({
    include: {
      group: true,
      user: true,
    }
  });

  console.log('Total transactions:', transactions.length);
  transactions.forEach(tx => {
    console.log(`TX ${tx.id}: amount=${tx.amount}, type=${tx.type}, userId=${tx.userId}, groupId=${tx.groupId}`);
  });
  
  const groups = await prisma.group.findMany({
    include: { users: true }
  });
  
  console.log('\nGroups:');
  groups.forEach(g => {
    console.log(`Group ${g.name} (${g.id}): users=[${g.users.map(u => u.email).join(', ')}]`);
  });
}

main().finally(() => prisma.$disconnect());
