import type { NextApiRequest, NextApiResponse } from "next";
import { usersMap, sanitizeUser } from "@/lib/mockStore";

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === "GET") {
    const list = Array.from(usersMap.values()).map(sanitizeUser);
    return res.status(200).json(list);
  }

  if (req.method === "POST") {
    const { name, email, password } = req.body ?? {};
    const id = String(usersMap.size + 1);
    const created = {
      id,
      name: String(name || "User"),
      email: String(email || `user${id}@jdate.app`),
      password: String(password || ""),
      createdAt: new Date().toISOString(),
    };
    usersMap.set(id, created);
    return res.status(201).json(sanitizeUser(created));
  }

  return res.status(405).json({ statusCode: 405, message: "Method Not Allowed" });
}
