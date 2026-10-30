import { api } from "@/services/api";
import type { AuthResponse } from "@/types";

export const authService = {
  login: (email: string, password: string) =>
    api.post<AuthResponse>("/auth/login", { email, password }),

  register: (name: string, email: string, password: string) =>
    api.post<AuthResponse>("/auth/register", { name, email, password }),

  getProfile: (token: string) =>
    api.get("/auth/profile", { token }),
};
