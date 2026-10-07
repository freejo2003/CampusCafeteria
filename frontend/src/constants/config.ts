export const API_BASE =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000/api";

export const STORAGE_KEYS = {
  token: "cafeteria_token",
  user: "cafeteria_user",
} as const;