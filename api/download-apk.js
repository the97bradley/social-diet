import { adminClient, cors } from "./_lib.mjs";

export function OPTIONS() {
  return new Response("ok", { headers: cors });
}

export async function GET(request) {
  const token = new URL(request.url).searchParams.get("token") ?? "";
  if (!token) {
    return new Response("Missing token", { status: 401, headers: cors });
  }

  const supabase = adminClient();
  const { data: release, error: lookupError } = await supabase
    .from("apk_releases")
    .select("object_path")
    .eq("token", token)
    .maybeSingle();

  if (lookupError || !release) {
    return new Response("Unauthorized", { status: 401, headers: cors });
  }

  const { data: signed, error: signError } = await supabase.storage
    .from("releases")
    .createSignedUrl(release.object_path, 120);

  if (signError || !signed?.signedUrl) {
    return new Response(signError?.message ?? "Could not sign download", {
      status: 500,
      headers: cors,
    });
  }

  return Response.redirect(signed.signedUrl, 302);
}
