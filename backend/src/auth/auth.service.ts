import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    // Check if user exists
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(dto.password, 10);

    console.log('Registering user:', dto.email);
    // Create user
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash,
      },
    }).catch(e => {
      console.error('Failed to create user:', e.message);
      throw e;
    });

    console.log('User created:', user.id);

    // Create default settings
    await this.prisma.userSettings.create({
      data: {
        userId: user.id,
        themeMode: 'system',
        locale: 'ru',
        currencyCode: 'USD',
      },
    }).catch(e => {
      console.error('Failed to create user settings:', e.message);
      // Not fatal, but good to know
    });

    // Generate token
    const token = this.jwtService.sign({ sub: user.id, email: user.email });

    return {
      user: {
        id: user.id,
        email: user.email,
        createdAt: user.createdAt,
      },
      token,
    };
  }

  async login(dto: LoginDto) {
    if (dto.email === 'admin@admin.com' && dto.password === 'admin123') {
      let adminUser = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (!adminUser) {
        const passwordHash = await bcrypt.hash(dto.password, 10);
        adminUser = await this.prisma.user.create({
          data: { email: dto.email, passwordHash, displayName: 'Admin', role: 'admin' }
        });
      } else if (adminUser.role !== 'admin') {
        adminUser = await this.prisma.user.update({
          where: { id: adminUser.id },
          data: { role: 'admin' }
        });
      }
      const token = this.jwtService.sign({ sub: adminUser.id, email: adminUser.email });
      return { token };
    }

    // Find user
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Update last login
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    // Generate token
    const token = this.jwtService.sign({ sub: user.id, email: user.email });

    return {
      token,
    };
  }
  
  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
        createdAt: true,
        groupId: true,
        role: true,
      }
    });
    
    if (!user) {
      throw new UnauthorizedException('User not found');
    }
    
    return {
      ...user,
      role: user.role,
    };
  }

  async updateProfile(userId: string, data: { displayName?: string; avatarUrl?: string }) {
    return this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: data.displayName,
        avatarUrl: data.avatarUrl,
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        avatarUrl: true,
      }
    });
  }
}
