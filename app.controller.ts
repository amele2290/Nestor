import { Controller, Get } from '@nestjs/common';

@Controller('api')
export class AppController {
  @Get()
  root() {
    return { message: 'Nestor Backend API — Welcome' };
  }
}
