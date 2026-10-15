import { createClient } from "@supabase/supabase-js";

export const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

export function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

export function adminClient() {
  const url = process.env.SUPABASE_URL ?? "";
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? "";
  if (!url || !key) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }
  return createClient(url, key);
}

export function validateSignup({ email, password, username }) {
  if (!String(email ?? "").includes("@") || String(password ?? "").length < 6) {
    return "Enter a valid email and a password of at least 6 characters.";
  }
  if (!/^[a-z0-9_]{3,24}$/.test(String(username ?? "").trim().toLowerCase())) {
    return "Username must be 3-24 letters, numbers, or underscores.";
  }
  return null;
}
