import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateUserDto } from './dto/create-user.dto.js';
import { UpdateUserDto } from './dto/update-user.dto.js';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  create(createUserDto: CreateUserDto) {
    // TODO: implement user creation
    return createUserDto;
  }

  findAll() {
    // TODO: implement fetching all users
    return [];
  }

  findOne(id: string) {
    // TODO: implement fetching a single user
    return { id };
  }

  findByEmail(email: string) {
    // TODO: implement fetching a user by email
    return { email };
  }

  update(id: string, updateUserDto: UpdateUserDto) {
    // TODO: implement updating a user
    return { id, ...updateUserDto };
  }

  remove(id: string) {
    // TODO: implement removing a user
    return { id };
  }
}
