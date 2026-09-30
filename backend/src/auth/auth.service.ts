import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AccessKeysService } from '../access-keys/access-keys.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class AuthService {
  constructor(
    private accessKeysService: AccessKeysService,
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async loginByAccessKey(key: string) {
    const accessKey = await this.accessKeysService.validateKey(key);
    const user = accessKey.user;

    if (!user || user.status === 'DISABLED') {
      throw new HttpException(
        { statusCode: 403, code: 'USER_DISABLED', message: 'User account is disabled' },
        HttpStatus.FORBIDDEN,
      );
    }

    const payload = {
      sub: user.id,
      role: user.role,
      displayName: user.displayName,
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        displayName: user.displayName,
        role: user.role,
      },
    };
  }

  async getProfile(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new HttpException(
        { statusCode: 404, code: 'USER_NOT_FOUND', message: 'User not found' },
        HttpStatus.NOT_FOUND,
      );
    }
    return {
      id: user.id,
      displayName: user.displayName,
      role: user.role,
      status: user.status,
    };
  }
}
