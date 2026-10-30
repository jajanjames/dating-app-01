import type { NextApiRequest, NextApiResponse } from "next";
import { getUserFromToken } from "@/lib/mockStore";
import { AUTH_TOKEN_KEY } from "@/utils/constants";

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== "GET") {
    return res.status(405).json({ statusCode: 405, message: "Method Not Allowed" });
  }

  const authHeader = req.headers.authorization;
  const cookieToken = req.cookies[AUTH_TOKEN_KEY];
  const token = authHeader || cookieToken;

  const user = getUserFromToken(token);
  if (!user) {
    return res.status(401).json({ statusCode: 401, message: "Unauthorized" });
  }

  return res.status(200).json(user);
}
