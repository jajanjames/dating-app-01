import type { NextApiRequest, NextApiResponse } from "next";
import { usersMap, issueToken, sanitizeUser } from "@/lib/mockStore";
import { AUTH_TOKEN_KEY } from "@/utils/constants";

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") {
    return res.status(405).json({ statusCode: 405, message: "Method Not Allowed" });
  }

  const { email, password } = req.body ?? {};
  if (!email || !password) {
    return res.status(400).json({ statusCode: 400, message: "Email and password are required" });
  }

  let matchedUser = Array.from(usersMap.values()).find(
    (u) => u.email.toLowerCase() === String(email).toLowerCase()
  );

  if (!matchedUser) {
    // Auto-provision user for seamless demo experience if not registered yet
    const id = String(usersMap.size + 1);
    matchedUser = {
      id,
      name: String(email).split("@")[0] || "JDATE User",
      email: String(email),
      password: String(password),
      createdAt: new Date().toISOString(),
    };
    usersMap.set(id, matchedUser);
  }

  const accessToken = issueToken(matchedUser.id);
  res.setHeader(
    "Set-Cookie",
    `${AUTH_TOKEN_KEY}=${accessToken}; Path=/; SameSite=Lax; Max-Age=86400`
  );

  return res.status(200).json({
    accessToken,
    user: sanitizeUser(matchedUser),
  });
}
