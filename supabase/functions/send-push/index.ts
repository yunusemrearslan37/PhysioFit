import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  getFirebaseRuntimeConfig,
  sendFirebasePushMessage,
} from "../_shared/firebase.ts";
import {
  createAuthorizedSupabaseClient,
  createServiceRoleSupabaseClient,
} from "../_shared/supabase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TITLE_MAX_LENGTH = 80;
const BODY_MAX_LENGTH = 240;

type RequestBody = {
  userId?: string;
  title?: string;
  body?: string;
  notificationType?: string;
  data?: Record<string, string | number | boolean | null>;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Only POST requests are supported." }, 405);
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

  const title = body?.title?.trim();
  const messageBody = body?.body?.trim();
  const notificationType = normalizeNotificationType(body?.notificationType);
  const targetUserId = body?.userId?.trim();

  if (!title || title.length > TITLE_MAX_LENGTH) {
    return jsonResponse(
      {
        error: `Title is required and must be at most ${TITLE_MAX_LENGTH} characters.`,
      },
      400,
    );
  }

  if (!messageBody || messageBody.length > BODY_MAX_LENGTH) {
    return jsonResponse(
      {
        error: `Body is required and must be at most ${BODY_MAX_LENGTH} characters.`,
      },
      400,
    );
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

  const resolvedUserId = targetUserId || user.id;
  if (resolvedUserId !== user.id) {
    return jsonResponse(
      {
        error: "You can only send test notifications to your own account.",
      },
      403,
    );
  }

  let firebaseConfig;
  try {
    firebaseConfig = getFirebaseRuntimeConfig();
  } catch (error) {
    return jsonResponse(
      {
        error: "Firebase runtime configuration is invalid.",
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }

  const adminSupabase = createServiceRoleSupabaseClient();
  const [preferencesResult, tokensResult] = await Promise.all([
    adminSupabase
      .from("notification_preferences")
      .select("*")
      .eq("user_id", resolvedUserId)
      .maybeSingle(),
    adminSupabase
      .from("device_tokens")
      .select("id, token, platform")
      .eq("user_id", resolvedUserId)
      .eq("is_active", true),
  ]);

  if (preferencesResult.error || tokensResult.error) {
    return jsonResponse(
      {
        error: "Failed to load notification settings.",
        details:
          preferencesResult.error?.message ?? tokensResult.error?.message ?? "Unknown error",
      },
      500,
    );
  }

  const preferences = preferencesResult.data;
  const tokens = tokensResult.data ?? [];

  if (!isNotificationAllowed(notificationType, preferences)) {
    await logNotificationAttempt(adminSupabase, {
      userId: resolvedUserId,
      notificationType,
      title,
      body: messageBody,
      status: "skipped",
      errorMessage: "User disabled this notification type.",
    });

    return jsonResponse({
      ok: true,
      sent: 0,
      skipped: 1,
      reason: "Notifications are disabled for this type.",
    });
  }

  const dataPayload = stringifyDataPayload(body?.data ?? {});
  const dedupKey = dataPayload.dedupKey;

  if (dedupKey) {
    const duplicateSent = await hasSentNotificationWithDedupKey(adminSupabase, {
      userId: resolvedUserId,
      notificationType,
      dedupKey,
    });

    if (duplicateSent) {
      await logNotificationAttempt(adminSupabase, {
        userId: resolvedUserId,
        notificationType,
        title,
        body: messageBody,
        payload: dataPayload,
        status: "skipped",
        errorMessage: "Duplicate notification dedupKey.",
      });

      return jsonResponse({
        ok: true,
        sent: 0,
        skipped: 1,
        reason: "Duplicate notification.",
      });
    }
  }

  if (tokens.length === 0) {
    await logNotificationAttempt(adminSupabase, {
      userId: resolvedUserId,
      notificationType,
      title,
      body: messageBody,
      status: "skipped",
      errorMessage: "No active device tokens found.",
    });

    return jsonResponse({
      ok: true,
      sent: 0,
      skipped: 1,
      reason: "No active device tokens found.",
    });
  }

  let sentCount = 0;
  const failures: Array<{ deviceTokenId: string; error: string }> = [];

  for (const tokenRow of tokens) {
    try {
      const response = await sendFirebasePushMessage(firebaseConfig, {
        token: tokenRow.token,
        notification: {
          title,
          body: messageBody,
        },
        data: dataPayload,
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      });

      await logNotificationAttempt(adminSupabase, {
        userId: resolvedUserId,
        deviceTokenId: tokenRow.id,
        notificationType,
        title,
        body: messageBody,
        payload: dataPayload,
        status: "sent",
        providerMessageId: String(response?.name ?? ""),
      });

      sentCount += 1;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);

      if (isInvalidDeviceTokenError(errorMessage)) {
        await adminSupabase
          .from("device_tokens")
          .update({
            is_active: false,
            updated_at: new Date().toISOString(),
          })
          .eq("id", tokenRow.id);
      }

      await logNotificationAttempt(adminSupabase, {
        userId: resolvedUserId,
        deviceTokenId: tokenRow.id,
        notificationType,
        title,
        body: messageBody,
        payload: dataPayload,
        status: "failed",
        errorMessage,
      });

      failures.push({
        deviceTokenId: tokenRow.id,
        error: errorMessage,
      });
    }
  }

  return jsonResponse({
    ok: true,
    sent: sentCount,
    failed: failures.length,
    failures,
  });
});

function normalizeNotificationType(value?: string) {
  return value?.trim().toLowerCase() || "general";
}

function isNotificationAllowed(
  notificationType: string,
  preferences: Record<string, unknown> | null,
) {
  if (!preferences) return true;
  if (preferences.notifications_enabled === false) return false;

  switch (notificationType) {
    case "ai_message":
      return preferences.push_ai_enabled !== false;
    case "plan_update":
      return preferences.push_plan_updates_enabled !== false;
    case "reengagement":
      return preferences.push_reengagement_enabled !== false;
    default:
      return true;
  }
}

function stringifyDataPayload(
  value: Record<string, string | number | boolean | null>,
) {
  return Object.fromEntries(
    Object.entries(value)
      .filter(([, entryValue]) => entryValue !== null)
      .map(([key, entryValue]) => [key, String(entryValue)]),
  );
}

function isInvalidDeviceTokenError(errorMessage: string) {
  const normalized = errorMessage.toLowerCase();
  return normalized.includes("unregistered") ||
    normalized.includes("registration token is not a valid fcm registration token") ||
    normalized.includes("requested entity was not found");
}

async function hasSentNotificationWithDedupKey(
  supabase: ReturnType<typeof createServiceRoleSupabaseClient>,
  {
    userId,
    notificationType,
    dedupKey,
  }: {
    userId: string;
    notificationType: string;
    dedupKey: string;
  },
) {
  const { data, error } = await supabase
    .from("notification_logs")
    .select("id")
    .eq("user_id", userId)
    .eq("notification_type", notificationType)
    .eq("status", "sent")
    .eq("payload->>dedupKey", dedupKey)
    .limit(1);

  if (error) {
    console.warn("Failed to check notification dedupKey:", error.message);
    return false;
  }

  return (data?.length ?? 0) > 0;
}

async function logNotificationAttempt(
  supabase: ReturnType<typeof createServiceRoleSupabaseClient>,
  {
    userId,
    deviceTokenId,
    notificationType,
    title,
    body,
    payload = {},
    status,
    errorMessage,
    providerMessageId,
  }: {
    userId: string;
    deviceTokenId?: string;
    notificationType: string;
    title: string;
    body: string;
    payload?: Record<string, string>;
    status: "sent" | "failed" | "skipped";
    errorMessage?: string;
    providerMessageId?: string;
  },
) {
  await supabase.from("notification_logs").insert({
    user_id: userId,
    device_token_id: deviceTokenId ?? null,
    notification_type: notificationType,
    title,
    body,
    payload,
    provider: "fcm",
    provider_message_id: providerMessageId ?? null,
    status,
    error_message: errorMessage ?? null,
    sent_at: status === "sent" ? new Date().toISOString() : null,
  });
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
