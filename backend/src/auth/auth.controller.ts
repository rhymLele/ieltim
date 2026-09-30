import { Controller, Post, Get, Body, UseGuards, HttpException, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AccessKeyLoginDto } from './dto/access-key.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ValidationPipe } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AccessKey } from '../access-keys/entities/access-key.entity';
import { User } from '../users/entities/user.entity';
import { Role } from '../common/enums/role.enum';
import { Status } from '../common/enums/status.enum';
import * as bcrypt from 'bcrypt';

@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    @InjectRepository(AccessKey) private keyRepo: Repository<AccessKey>,
    @InjectRepository(User) private userRepo: Repository<User>,
  ) {}

  @Post('access-key')
  login(@Body(new ValidationPipe({ whitelist: true })) dto: AccessKeyLoginDto) {
    return this.authService.loginByAccessKey(dto.key);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: { id: string }) {
    return this.authService.getProfile(user.id);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  logout() {
    return { success: true };
  }

  @Post('setup')
  async setup() {
    const existingKeys = await this.keyRepo.find();
    if (existingKeys.length > 0) {
      throw new HttpException('Setup already completed', HttpStatus.FORBIDDEN);
    }

    const admin = this.userRepo.create({ displayName: 'Admin', role: Role.ADMIN, status: Status.ACTIVE });
    const user = this.userRepo.create({ displayName: 'User', role: Role.USER, status: Status.ACTIVE });
    const [savedAdmin, savedUser] = await this.userRepo.save([admin, user]);

    const adminKeyHash = await bcrypt.hash('ADMIN-2026-KEY', 10);
    const userKeyHash = await bcrypt.hash('USER-2026-KEY', 10);

    await this.keyRepo.save([
      this.keyRepo.create({ keyHash: adminKeyHash, userId: savedAdmin.id, status: Status.ACTIVE }),
      this.keyRepo.create({ keyHash: userKeyHash, userId: savedUser.id, status: Status.ACTIVE }),
    ]);

    return {
      message: 'Setup complete',
      adminKey: 'ADMIN-2026-KEY',
      userKey: 'USER-2026-KEY',
    };
  }
}
