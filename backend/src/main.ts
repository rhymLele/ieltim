import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import * as express from 'express';
import * as path from 'path';
import * as fs from 'fs';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bodyParser: false });
  configureApp(app);

  const possiblePaths = [
    path.join(__dirname, '../../../frontend/build/web'),
    path.join(__dirname, '../../frontend/build/web'),
    path.join(process.cwd(), '../frontend/build/web'),
    path.join(process.cwd(), 'frontend/build/web'),
  ];
  const distPath = possiblePaths.find((p) => fs.existsSync(p)) || '';
  if (distPath && fs.existsSync(distPath)) {
    const expressApp = app.getHttpAdapter().getInstance();
    expressApp.use(express.static(distPath));
    expressApp.use(
      (
        req: express.Request,
        res: express.Response,
        next: express.NextFunction,
      ) => {
        if (req.path.startsWith('/api') || req.path === '/health')
          return next();
        if (req.method !== 'GET') return next();
        res.sendFile(path.join(distPath, 'index.html'));
      },
    );
    console.log(`Serving Flutter web from ${distPath}`);
  } else {
    // Web deploy riêng (Render Static Site) hoặc chưa build: service này chỉ phục vụ API.
    console.log('No Flutter web build (frontend/build/web): serving API only');
  }

  const port = process.env.PORT ? parseInt(process.env.PORT) : 3000;
  await app.listen(port);
  console.log(`Backend running on http://localhost:${port}/api`);
}
bootstrap();
