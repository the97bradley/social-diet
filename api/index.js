import { cors, json } from "./_lib.mjs";

export function OPTIONS() {
  return new Response("ok", { headers: cors });
}

export function GET() {
  return json({ ok: true, service: "social-diet" });
}
