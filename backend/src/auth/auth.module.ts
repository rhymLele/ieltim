import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { UsersModule } from '../users/users.module';
import { AccessKeysModule } from '../access-keys/access-keys.module';
import { User } from '../users/entities/user.entity';
import { AccessKey } from '../access-keys/entities/access-key.entity';

@Module({
  imports: [
    UsersModule,
    AccessKeysModule,
    TypeOrmModule.forFeature([User, AccessKey]),
    PassportModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET'),
        signOptions: { expiresIn: config.get('JWT_EXPIRES_IN', '7d') },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
