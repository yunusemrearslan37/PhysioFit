import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  getFirebaseRuntimeConfig,
  sendFirebasePushMessage,
} from "../_shared/firebase.ts";
import { createServiceRoleSupabaseClient } from "../_shared/supabase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

const INACTIVE_AFTER_DAYS = 3;
const IGNORE_AFTER_DAYS = 30;
const MIN_DAYS_BETWEEN_REENGAGEMENT = 7;
const BATCH_SIZE = 100;
const NOTIFICATION_TYPE = "reengagement";

type UserProfileRow = {
  id: string;
  name: string | null;
  last_active_at: string | null;
};

type DeviceTokenRow = {
  id: string;
  token: string;
  platform: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Only POST requests are supported." }, 405);
  }

  if (!isAuthorizedCronRequest(req)) {
    return jsonResponse({ error: "Unauthorized cron request." }, 401);
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
  const now = new Date();
  const inactiveBefore = subtractDays(now, INACTIVE_AFTER_DAYS);
  const ignoreBefore = subtractDays(now, IGNORE_AFTER_DAYS);

  const { data: users, error: usersError } = await adminSupabase
    .from("user_profiles")
    .select("id, name, last_active_at")
    .eq("onboarding_completed", true)
    .lt("last_active_at", inactiveBefore.toISOString())
    .gte("last_active_at", ignoreBefore.toISOString())
    .order("last_active_at", { ascending: true })
    .limit(BATCH_SIZE);

  if (usersError) {
    return jsonResponse(
      {
        error: "Failed to load inactive users.",
        details: usersError.message,
      },
      500,
    );
  }

  const stats = {
    checked: users?.length ?? 0,
    sent: 0,
    skipped: 0,
    failed: 0,
  };

  for (const user of (users ?? []) as UserProfileRow[]) {
    const result = await sendReengagementToUser({
      supabase: adminSupabase,
      firebaseConfig,
      user,
      now,
    });

    if (result === "sent") {
      stats.sent += 1;
    } else if (result === "failed") {
      stats.failed += 1;
    } else {
      stats.skipped += 1;
    }
  }

  return jsonResponse({
    ok: true,
    ...stats,
  });
});

async function sendReengagementToUser({
  supabase,
  firebaseConfig,
  user,
  now,
}: {
  supabase: ReturnType<typeof createServiceRoleSupabaseClient>;
  firebaseConfig: ReturnType<typeof getFirebaseRuntimeConfig>;
  user: UserProfileRow;
  now: Date;
}): Promise<"sent" | "skipped" | "failed"> {
  const [preferencesResult, tokensResult, recentLogResult] = await Promise.all([
    supabase
      .from("notification_preferences")
      .select("*")
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase
      .from("device_tokens")
      .select("id, token, platform")
      .eq("user_id", user.id)
      .eq("is_active", true),
    supabase
      .from("notification_logs")
      .select("id, created_at")
      .eq("user_id", user.id)
      .eq("notification_type", NOTIFICATION_TYPE)
      .eq("status", "sent")
      .gte(
        "created_at",
        subtractDays(now, MIN_DAYS_BETWEEN_REENGAGEMENT).toISOString(),
      )
      .limit(1),
  ]);

  if (preferencesResult.error || tokensResult.error || recentLogResult.error) {
    await logNotificationAttempt(supabase, {
      userId: user.id,
      title: "Seni özledik",
      body: "Bildirim ayarları kontrol edilemedi.",
      status: "failed",
      errorMessage:
        preferencesResult.error?.message ??
        tokensResult.error?.message ??
        recentLogResult.error?.message ??
        "Unknown error",
    });
    return "failed";
  }

  const preferences = preferencesResult.data;
  const tokens = (tokensResult.data ?? []) as DeviceTokenRow[];

  if (!isReengagementAllowed(preferences)) {
    await logNotificationAttempt(supabase, {
      userId: user.id,
      title: "Seni özledik",
      body: "Kullanıcı bu bildirim türünü kapattı.",
      status: "skipped",
      errorMessage: "User disabled reengagement notifications.",
    });
    return "skipped";
  }

  if ((recentLogResult.data?.length ?? 0) > 0) {
    await logNotificationAttempt(supabase, {
      userId: user.id,
      title: "Seni özledik",
      body: "Yakın zamanda reengagement bildirimi gönderildi.",
      status: "skipped",
      errorMessage: "Frequency cap reached.",
    });
    return "skipped";
  }

  if (tokens.length === 0) {
    await logNotificationAttempt(supabase, {
      userId: user.id,
      title: "Seni özledik",
      body: "Aktif cihaz tokeni yok.",
      status: "skipped",
      errorMessage: "No active device tokens found.",
    });
    return "skipped";
  }

  const title = "Seni özledik";
  const body = buildReengagementBody(user.name);
  const payload = {
    type: NOTIFICATION_TYPE,
    lastActiveAt: user.last_active_at ?? "",
    dedupKey: buildWeeklyDedupKey(user.id, now),
  };

  let sentAny = false;
  let failedAny = false;

  for (const tokenRow of tokens) {
    try {
      const response = await sendFirebasePushMessage(firebaseConfig, {
        token: tokenRow.token,
        notification: {
          title,
          body,
        },
        data: payload,
        android: {
          priority: "high",
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
        },
      });

      await logNotificationAttempt(supabase, {
        userId: user.id,
        deviceTokenId: tokenRow.id,
        title,
        body,
        payload,
        status: "sent",
        providerMessageId: getProviderMessageId(response),
      });

      sentAny = true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      failedAny = true;

      if (isInvalidDeviceTokenError(errorMessage)) {
        await supabase
          .from("device_tokens")
          .update({
            is_active: false,
            updated_at: new Date().toISOString(),
          })
          .eq("id", tokenRow.id);
      }

      await logNotificationAttempt(supabase, {
        userId: user.id,
        deviceTokenId: tokenRow.id,
        title,
        body,
        payload,
        status: "failed",
        errorMessage,
      });
    }
  }

  if (sentAny) return "sent";
  if (failedAny) return "failed";
  return "skipped";
}

function isAuthorizedCronRequest(req: Request) {
  const configuredSecret = Deno.env.get("REENGAGEMENT_CRON_SECRET")?.trim();
  if (!configuredSecret) return false;

  const headerSecret = req.headers.get("x-cron-secret")?.trim();
  const bearerSecret = req.headers
    .get("Authorization")
    ?.replace(/^Bearer\s+/i, "")
    .trim();

  return headerSecret === configuredSecret || bearerSecret === configuredSecret;
}

function isReengagementAllowed(preferences: Record<string, unknown> | null) {
  if (!preferences) return true;
  if (preferences.notifications_enabled === false) return false;
  return preferences.push_reengagement_enabled !== false;
}

function buildReengagementBody(name: string | null) {
  const greeting = name?.trim() ? `${name.trim()}, ` : "";
  return `${greeting}programın seni bekliyor. Bugün 15 dakika bile hedefe dönmek için yeterli.`;
}

function buildWeeklyDedupKey(userId: string, now: Date) {
  const startOfYear = new Date(Date.UTC(now.getUTCFullYear(), 0, 1));
  const dayOfYear = Math.floor(
    (Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()) -
      startOfYear.getTime()) /
      86400000,
  ) + 1;
  const week = Math.ceil(dayOfYear / 7);
  return `reengagement_${userId}_${now.getUTCFullYear()}_w${week}`;
}

function subtractDays(date: Date, days: number) {
  return new Date(date.getTime() - days * 24 * 60 * 60 * 1000);
}

function isInvalidDeviceTokenError(errorMessage: string) {
  const normalized = errorMessage.toLowerCase();
  return normalized.includes("unregistered") ||
    normalized.includes("registration token is not a valid fcm registration token") ||
    normalized.includes("requested entity was not found");
}

function getProviderMessageId(response: Record<string, unknown> | null) {
  return String(response?.name ?? "");
}

async function logNotificationAttempt(
  supabase: ReturnType<typeof createServiceRoleSupabaseClient>,
  {
    userId,
    deviceTokenId,
    title,
    body,
    payload = {},
    status,
    errorMessage,
    providerMessageId,
  }: {
    userId: string;
    deviceTokenId?: string;
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
    notification_type: NOTIFICATION_TYPE,
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
