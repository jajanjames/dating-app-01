import type { User } from "@/types";

export interface StoredUser extends User {
  password?: string;
  createdAt: string;
}

const globalStore = globalThis as unknown as {
  __jdateUsers?: Map<string, StoredUser>;
  __jdateTokens?: Map<string, string>;
};

if (!globalStore.__jdateUsers) {
  const initialUsers = new Map<string, StoredUser>();
  initialUsers.set("1", {
    id: "1",
    name: "Sabari Nath",
    email: "demo@jdate.app",
    password: "password123",
    createdAt: new Date().toISOString(),
  });
  globalStore.__jdateUsers = initialUsers;
}

if (!globalStore.__jdateTokens) {
  const initialTokens = new Map<string, string>();
  initialTokens.set("demo-jwt-token-1", "1");
  globalStore.__jdateTokens = initialTokens;
}

export const usersMap = globalStore.__jdateUsers;
export const tokensMap = globalStore.__jdateTokens;

export function sanitizeUser(user: StoredUser): User {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
  };
}

export function issueToken(userId: string): string {
  const token = `jdate-token-${userId}-${Date.now()}`;
  tokensMap.set(token, userId);
  return token;
}

export function getUserFromToken(token?: string): User | null {
  if (!token) return null;
  const cleanToken = token.replace(/^Bearer\s+/i, "").trim();
  const userId = tokensMap.get(cleanToken);
  if (userId) {
    const found = usersMap.get(userId);
    if (found) return sanitizeUser(found);
  }
  const firstUser = usersMap.values().next().value;
  return firstUser ? sanitizeUser(firstUser) : null;
}
