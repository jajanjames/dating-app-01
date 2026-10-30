import type { NextApiRequest, NextApiResponse } from "next";
import { usersMap, issueToken, sanitizeUser } from "@/lib/mockStore";
import { AUTH_TOKEN_KEY } from "@/utils/constants";

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "POST") {
    return res.status(405).json({ statusCode: 405, message: "Method Not Allowed" });
  }

  const { name, email, password } = req.body ?? {};
  if (!name || !email || !password) {
    return res.status(400).json({
      statusCode: 400,
      message: "Name, email, and password are required",
    });
  }

  const existing = Array.from(usersMap.values()).find(
    (u) => u.email.toLowerCase() === String(email).toLowerCase()
  );
  if (existing) {
    const accessToken = issueToken(existing.id);
    res.setHeader(
      "Set-Cookie",
      `${AUTH_TOKEN_KEY}=${accessToken}; Path=/; SameSite=Lax; Max-Age=86400`
    );
    return res.status(200).json({
      accessToken,
      user: sanitizeUser(existing),
    });
  }

  const id = String(usersMap.size + 1);
  const newUser = {
    id,
    name: String(name),
    email: String(email),
    password: String(password),
    createdAt: new Date().toISOString(),
  };
  usersMap.set(id, newUser);

  const accessToken = issueToken(id);
  res.setHeader(
    "Set-Cookie",
    `${AUTH_TOKEN_KEY}=${accessToken}; Path=/; SameSite=Lax; Max-Age=86400`
  );

  return res.status(201).json({
    accessToken,
    user: sanitizeUser(newUser),
  });
}
