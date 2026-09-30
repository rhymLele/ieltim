import * as bcrypt from 'bcrypt';
import { DataSource } from 'typeorm';
import { User } from '../src/users/entities/user.entity';
import { AccessKey } from '../src/access-keys/entities/access-key.entity';
import { Role } from '../src/common/enums/role.enum';
import { Status } from '../src/common/enums/status.enum';

async function seed() {
  let config: any;
  const databaseUrl = process.env.DATABASE_URL;
  if (databaseUrl) {
    const url = new URL(databaseUrl);
    config = {
      type: 'postgres',
      host: url.hostname,
      port: parseInt(url.port) || 5432,
      username: decodeURIComponent(url.username),
      password: decodeURIComponent(url.password),
      database: url.pathname.replace(/^\//, ''),
    };
  } else {
    config = {
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT) || 5432,
      username: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'ielts_knowledge_hub',
    };
  }

  const dataSource = new DataSource({
    ...config,
    entities: [User, AccessKey],
    synchronize: true,
  });

  await dataSource.initialize();
  const repo = dataSource.getRepository(User);
  const keyRepo = dataSource.getRepository(AccessKey);

  const admin = await repo.findOne({ where: { role: Role.ADMIN } });
  if (!admin) {
    const adminUser = repo.create({
      displayName: 'Admin',
      role: Role.ADMIN,
      status: Status.ACTIVE,
    });
    await repo.save(adminUser);

    const adminKey = await bcrypt.hash('ADMIN-2026-KEY', 10);
    await keyRepo.save(
      keyRepo.create({
        keyHash: adminKey,
        userId: adminUser.id,
        status: Status.ACTIVE,
      }),
    );
    console.log('Admin user + access key created');
    console.log('Admin key: ADMIN-2026-KEY');
  } else {
    console.log('Admin already exists');
  }

  const user = await repo.findOne({ where: { role: Role.USER, displayName: 'Test User' } });
  if (!user) {
    const testUser = repo.create({
      displayName: 'Test User',
      role: Role.USER,
      status: Status.ACTIVE,
    });
    await repo.save(testUser);

    const userKey = await bcrypt.hash('USER-2026-KEY', 10);
    await keyRepo.save(
      keyRepo.create({
        keyHash: userKey,
        userId: testUser.id,
        status: Status.ACTIVE,
      }),
    );
    console.log('Test user + access key created');
    console.log('User key: USER-2026-KEY');
  } else {
    console.log('Test user already exists');
  }

  await dataSource.destroy();
}

seed().catch(console.error);
