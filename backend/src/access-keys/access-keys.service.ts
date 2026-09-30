import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AccessKey } from './entities/access-key.entity';
import { Status } from '../common/enums/status.enum';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AccessKeysService {
  constructor(
    @InjectRepository(AccessKey)
    private accessKeysRepo: Repository<AccessKey>,
  ) {}

  async validateKey(key: string): Promise<AccessKey> {
    const keys = await this.accessKeysRepo
      .createQueryBuilder('ak')
      .leftJoinAndSelect('ak.user', 'user')
      .getMany();

    let accessKey: AccessKey | null = null;
    for (const k of keys) {
      const match = await bcrypt.compare(key, k.keyHash);
      if (match) {
        accessKey = k;
        break;
      }
    }

    if (!accessKey) {
      throw new HttpException(
        { statusCode: 401, code: 'INVALID_ACCESS_KEY', message: 'Access key is invalid' },
        HttpStatus.UNAUTHORIZED,
      );
    }

    if (accessKey.status === Status.DISABLED) {
      throw new HttpException(
        { statusCode: 403, code: 'KEY_DISABLED', message: 'Access key is disabled' },
        HttpStatus.FORBIDDEN,
      );
    }

    if (accessKey.expiresAt && accessKey.expiresAt < new Date()) {
      throw new HttpException(
        { statusCode: 403, code: 'KEY_EXPIRED', message: 'Access key has expired' },
        HttpStatus.FORBIDDEN,
      );
    }

    accessKey.lastUsedAt = new Date();
    await this.accessKeysRepo.save(accessKey);

    return accessKey;
  }

  findByUserId(userId: string): Promise<AccessKey[]> {
    return this.accessKeysRepo.find({ where: { userId } });
  }

  async create(userId: string, key: string, expiresAt?: Date): Promise<AccessKey> {
    const keyHash = await bcrypt.hash(key, 10);
    const accessKey = this.accessKeysRepo.create({
      keyHash,
      userId,
      expiresAt: expiresAt || null,
      status: Status.ACTIVE,
    });
    return this.accessKeysRepo.save(accessKey);
  }

  async updateStatus(id: string, status: Status): Promise<AccessKey> {
    const accessKey = await this.accessKeysRepo.findOne({ where: { id } });
    if (!accessKey) {
      throw new HttpException(
        { statusCode: 404, code: 'NOT_FOUND', message: 'Access key not found' },
        HttpStatus.NOT_FOUND,
      );
    }
    accessKey.status = status;
    return this.accessKeysRepo.save(accessKey);
  }

  findAll(): Promise<AccessKey[]> {
    return this.accessKeysRepo.find({ order: { createdAt: 'DESC' } });
  }
}
