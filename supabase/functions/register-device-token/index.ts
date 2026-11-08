import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  createAuthorizedSupabaseClient,
  createServiceRoleSupabaseClient,
} from "../_shared/supabase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const allowedPlatforms = new Set(["android", "ios", "web"]);

type RequestBody = {
  token?: string;
  platform?: string;
  deviceLabel?: string;
  appVersion?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { error: "Only POST requests are supported." },
      405,
    );
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return jsonResponse({ error: "Missing Authorization header." }, 401);
  }

  let body: RequestBody | null = null;
  try {
    body = await req.json();
  } catch (_) {
    return jsonResponse({ error: "Invalid JSON body." }, 400);
  }

  const token = body?.token?.trim();
  const platform = body?.platform?.trim().toLowerCase();
  const deviceLabel = body?.deviceLabel?.trim() || null;
  const appVersion = body?.appVersion?.trim() || null;

  if (!token || token.length < 20) {
    return jsonResponse({ error: "A valid device token is required." }, 400);
  }

  if (!platform || !allowedPlatforms.has(platform)) {
    return jsonResponse({ error: "Platform must be android, ios, or web." }, 400);
  }

  const supabase = createAuthorizedSupabaseClient(authorization);
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return jsonResponse(
      {
        error: "Unauthorized request.",
        details: userError?.message ?? "User not found.",
      },
      401,
    );
  }

  const adminSupabase = createServiceRoleSupabaseClient();
  const { data, error } = await adminSupabase
    .from("device_tokens")
    .upsert(
      {
        user_id: user.id,
        token,
        platform,
        device_label: deviceLabel,
        app_version: appVersion,
        is_active: true,
        last_seen_at: new Date().toISOString(),
      },
      {
        onConflict: "token",
      },
    )
    .select("id, user_id, platform, is_active, last_seen_at")
    .single();

  if (error) {
    return jsonResponse(
      {
        error: "Failed to register device token.",
        details: error.message,
      },
      500,
    );
  }

  return jsonResponse({
    ok: true,
    deviceToken: data,
  });
});

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
