import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // BigInt and Decimal serialization fix
  (BigInt.prototype as any).toJSON = function () {
    return Number(this);
  };
  
  // Handle Decimal serialization for Prisma
  try {
    const { Decimal } = require('@prisma/client/runtime/library');
    if (Decimal) {
      (Decimal.prototype as any).toJSON = function () {
        return this.toNumber();
      };
    }
  } catch (e) {
    // Fallback or ignore
  }

  // Enable CORS for Flutter app
  app.enableCors({
    origin: true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });
  
  // Enable validation
  /* app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  ); */
  
  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 Backend running on http://localhost:${port}`);
}
bootstrap();
