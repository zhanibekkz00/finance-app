import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class GroupsService {
    constructor(private prisma: PrismaService) { }

    private generateJoinCode(): string {
        return crypto.randomBytes(3).toString('hex').toUpperCase();
    }

    async create(userId: string, name: string) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (user?.groupId) {
            throw new ConflictException('User is already in a group');
        }

        const joinCode = this.generateJoinCode();

        const group = await this.prisma.group.create({
            data: {
                name,
                joinCode,
                users: {
                    connect: { id: userId },
                },
            },
        });

        return group;
    }

    async join(userId: string, joinCode: string) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (user?.groupId) {
            throw new ConflictException('User is already in a group');
        }

        const group = await this.prisma.group.findUnique({
            where: { joinCode: joinCode.toUpperCase() },
        });

        if (!group) {
            throw new NotFoundException('Group not found');
        }

        await this.prisma.user.update({
            where: { id: userId },
            data: { groupId: group.id },
        });

        return group;
    }

    async getGroupInfo(userId: string) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            include: {
                group: {
                    include: {
                        users: {
                            select: {
                                id: true,
                                email: true,
                            },
                        },
                    },
                },
            },
        });

        if (!user?.groupId) {
            return null;
        }

        return user.group;
    }

    async leaveGroup(userId: string) {
        await this.prisma.user.update({
            where: { id: userId },
            data: { groupId: null },
        });

        // Optional: Clean up empty groups
    }

    async getGroupStats(userId: string) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { groupId: true },
        });

        if (!user?.groupId) {
            throw new NotFoundException('User is not in a group');
        }

        // Retroactive fix: ensure all transactions for users in this group have the groupId
        const groupUsers = await this.prisma.user.findMany({
            where: { groupId: user.groupId },
            select: { id: true },
        });
        const userIds = groupUsers.map(u => u.id);

        await this.prisma.transaction.updateMany({
            where: {
                userId: { in: userIds },
                groupId: null,
            },
            data: {
                groupId: user.groupId,
            },
        });

        const stats = await this.prisma.transaction.groupBy({
            by: ['userId'],
            where: {
                groupId: user.groupId,
                type: 'expense',
            },
            _sum: {
                amount: true,
            },
        });

        // Enrich with user emails/names
        const enrichedStats = await Promise.all(
            stats.map(async (stat) => {
                const u = await this.prisma.user.findUnique({
                    where: { id: stat.userId },
                    select: { email: true, displayName: true },
                });
                return {
                    userId: stat.userId,
                    name: u?.displayName || u?.email || 'Unknown',
                    total: Number(stat._sum.amount || 0),
                };
            }),
        );

        return enrichedStats;
    }
}
