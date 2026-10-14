import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  const url = new URL(req.url);
  const token = url.searchParams.get("token") ?? "";
  if (!token) {
    return new Response("Missing token", { status: 401, headers: cors });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

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
});
