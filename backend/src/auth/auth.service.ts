import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto } from './dto/register.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  async register(registerDto: RegisterDto) {
    // TODO: implement registration (hash password, create user, issue token)
    return registerDto;
  }

  async login(loginDto: LoginDto) {
    // TODO: implement login (validate credentials, issue token)
    return loginDto;
  }

  async validateUser(email: string, password: string) {
    // TODO: implement credential validation
    return { email, password };
  }
}
