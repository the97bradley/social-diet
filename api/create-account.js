import { adminClient, cors, json, validateSignup } from "./_lib.mjs";

export function OPTIONS() {
  return new Response("ok", { headers: cors });
}

export async function POST(request) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const email = String(body.email ?? "").trim();
  const password = String(body.password ?? "");
  const username = String(body.username ?? "").trim().toLowerCase();
  const displayName = String(body.display_name ?? "").trim() || username;

  const invalid = validateSignup({ email, password, username });
  if (invalid) return json({ error: invalid }, 400);

  const supabase = adminClient();
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
}
