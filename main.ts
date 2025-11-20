import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const port = process.env.PORT || 4000;
  app.enableCors();
  await app.listen(port);
  console.log(`Backend listening on http://localhost:${port}`);
}
bootstrap();
