import { Controller, Get, Post, Body, UseGuards, Delete, Request } from '@nestjs/common';
import { GroupsService } from './groups.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('groups')
@UseGuards(JwtAuthGuard)
export class GroupsController {
    constructor(private readonly groupsService: GroupsService) { }

    @Post()
    create(@Request() req, @Body('name') name: string) {
        return this.groupsService.create(req.user.id, name);
    }

    @Post('join')
    join(@Request() req, @Body('joinCode') joinCode: string) {
        return this.groupsService.join(req.user.id, joinCode);
    }

    @Get('me')
    getGroupInfo(@Request() req) {
        return this.groupsService.getGroupInfo(req.user.id);
    }

    @Delete('leave')
    leaveGroup(@Request() req) {
        return this.groupsService.leaveGroup(req.user.id);
    }

    @Get('stats')
    getGroupStats(@Request() req) {
        return this.groupsService.getGroupStats(req.user.id);
    }
}
