import { useState, useEffect, useCallback } from "react";
import type { User } from "@/types";
import { authService } from "@/services/auth.service";
import { AUTH_TOKEN_KEY } from "@/utils/constants";

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    const token =
      typeof window !== "undefined" ? localStorage.getItem(AUTH_TOKEN_KEY) : null;
    if (token) {
      setIsLoading(true);
      authService
        .getProfile(token)
        .then((profile) => setUser(profile as User))
        .catch(() => {
          localStorage.removeItem(AUTH_TOKEN_KEY);
        })
        .finally(() => setIsLoading(false));
    }
  }, []);

  const logout = useCallback(() => {
    if (typeof window !== "undefined") {
      localStorage.removeItem(AUTH_TOKEN_KEY);
      document.cookie = `${AUTH_TOKEN_KEY}=; Path=/; Max-Age=0`;
    }
    setUser(null);
  }, []);

  return { user, setUser, isLoading, setIsLoading, logout };
}
