import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let body: {
    email?: string;
    password?: string;
    username?: string;
    display_name?: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const email = String(body.email ?? "").trim();
  const password = String(body.password ?? "");
  const username = String(body.username ?? "").trim().toLowerCase();
  const displayName = String(body.display_name ?? "").trim() || username;

  if (!email.includes("@") || password.length < 6) {
    return json({
      error: "Enter a valid email and a password of at least 6 characters.",
    }, 400);
  }
  if (!/^[a-z0-9_]{3,24}$/.test(username)) {
    return json({
      error: "Username must be 3-24 letters, numbers, or underscores.",
    }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  // shortcut: skip mailer, add custom SMTP + confirmations when abuse shows up
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { username, display_name: displayName },
  });

  if (error) {
    const text = `${error.code ?? ""} ${error.message}`.toLowerCase();
    if (
      text.includes("already") ||
      text.includes("registered") ||
      text.includes("email_exists") ||
      error.status === 422
    ) {
      return json({
        error: "That email already has an account. Sign in instead.",
      }, 409);
    }
    return json({ error: error.message }, 400);
  }

  return json({ ok: true, user_id: data.user?.id });
});
