import type { NextApiRequest, NextApiResponse } from "next";
import { usersMap, sanitizeUser } from "@/lib/mockStore";

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  const { id } = req.query;
  const userId = String(id);
  const existing = usersMap.get(userId);

  if (req.method === "GET") {
    if (!existing) {
      return res.status(404).json({ statusCode: 404, message: "User not found" });
    }
    return res.status(200).json(sanitizeUser(existing));
  }

  if (req.method === "PATCH" || req.method === "PUT") {
    if (!existing) {
      return res.status(404).json({ statusCode: 404, message: "User not found" });
    }
    const updated = {
      ...existing,
      ...(req.body?.name ? { name: String(req.body.name) } : {}),
      ...(req.body?.email ? { email: String(req.body.email) } : {}),
    };
    usersMap.set(userId, updated);
    return res.status(200).json(sanitizeUser(updated));
  }

  if (req.method === "DELETE") {
    usersMap.delete(userId);
    return res.status(200).json({ id: userId, deleted: true });
  }

  return res.status(405).json({ statusCode: 405, message: "Method Not Allowed" });
}
