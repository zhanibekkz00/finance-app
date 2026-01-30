import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { nanoid } from 'nanoid';

@Injectable()
export class GroupsService {
    constructor(private prisma: PrismaService) { }

    async create(userId: string, name: string) {
        const user = await this.prisma.user.findUnique({ where: { id: userId } });
        if (user?.groupId) {
            throw new ConflictException('User is already in a group');
        }

        const joinCode = nanoid(8).toUpperCase();

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
}
