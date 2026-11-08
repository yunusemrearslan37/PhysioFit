import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  buildGeminiGenerateContentUrl,
  getGeminiRuntimeConfig,
} from "../_shared/gemini.ts";
import { createAuthorizedSupabaseClient } from "../_shared/supabase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const MAX_MESSAGE_LENGTH = 1200;
const MAX_USER_MESSAGES_PER_DAY = 100;
const MIN_SECONDS_BETWEEN_MESSAGES = 3;
const RECENT_MESSAGES_FETCH_LIMIT = 16;
const ACTIVE_MEMORY_MAX_MESSAGES = 8;
const ACTIVE_MEMORY_MIN_MESSAGES = 4;
const ACTIVE_MEMORY_CHAR_BUDGET = 2400;
const MEMORY_SUMMARY_USER_ITEMS = 2;
const MEMORY_SUMMARY_ASSISTANT_ITEMS = 1;
const GEMINI_TIMEOUT_MS = 20_000;
const GEMINI_MAX_RETRIES = 2;
const RETRYABLE_STATUS_CODES = new Set([429, 500, 502, 503, 504]);

type RequestBody = {
  message?: string;
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Only POST requests are supported." }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  let body: RequestBody | null = null;

  try {
    body = await req.json();
  } catch (_) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body." }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const message = body?.message?.trim();
  if (!message) {
    return new Response(
      JSON.stringify({ error: "Message is required." }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (message.length > MAX_MESSAGE_LENGTH) {
    return new Response(
      JSON.stringify({
        error: `Message is too long. Maximum ${MAX_MESSAGE_LENGTH} characters allowed.`,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return new Response(
      JSON.stringify({ error: "Missing Authorization header." }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  let geminiConfig;

  try {
    geminiConfig = getGeminiRuntimeConfig();
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Gemini runtime configuration is invalid.",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const supabase = createAuthorizedSupabaseClient(authorization);

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    return new Response(
      JSON.stringify({
        error: "Unauthorized request.",
        details: userError?.message ?? "User not found.",
      }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const usageCheck = await checkUsageLimits(supabase, user.id);
  if (!usageCheck.allowed) {
    return new Response(
      JSON.stringify({
        error: usageCheck.error,
      }),
      {
        status: usageCheck.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const todayDate = new Date().toISOString().split("T")[0];

  const [
    goalResult,
    metricResult,
    limitationResult,
    workoutResult,
    profileResult,
    analyticsResult,
    nutritionResult,
  ] = await Promise.all([
    supabase
      .from("user_goals")
      .select(
        "goal_type, activity_level, experience_level, workout_days_per_week, workout_days, program_weeks",
      )
      .eq("user_id", user.id)
      .eq("is_active", true)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase
      .from("user_metrics")
      .select("height, weight, body_fat_percentage")
      .eq("user_id", user.id)
      .order("recorded_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase
      .from("user_limitations")
      .select("body_part, limitation_type, severity, notes")
      .eq("user_id", user.id)
      .eq("is_active", true)
      .order("created_at", { ascending: false }),
    supabase
      .from("workouts")
      .select("name, exercises, weeks, is_active, created_at")
      .eq("user_id", user.id)
      .eq("is_active", true)
      .maybeSingle(),
    supabase
      .from("user_profiles")
      .select("birth_date, gender")
      .eq("id", user.id)
      .maybeSingle(),
    supabase
      .from("user_analytics")
      .select("calories_burned")
      .eq("user_id", user.id)
      .eq("date", todayDate)
      .maybeSingle(),
    supabase
      .from("daily_nutrition")
      .select("calories_consumed")
      .eq("user_id", user.id)
      .eq("date", todayDate)
      .maybeSingle(),
  ]);

  if (goalResult.error || metricResult.error || limitationResult.error || workoutResult.error) {
    console.error("Context fetch error", {
      goalError: goalResult.error?.message,
      metricError: metricResult.error?.message,
      limitationError: limitationResult.error?.message,
      workoutError: workoutResult.error?.message,
      userId: user.id,
    });

    return new Response(
      JSON.stringify({
        error: "Kullanıcı bilgileri alınırken bir sorun oluştu. Lütfen tekrar deneyin.",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  if (profileResult.error) {
    console.error("Profile fetch error", profileResult.error.message);
  }
  if (analyticsResult.error) {
    console.error("Analytics fetch error", analyticsResult.error.message);
  }
  if (nutritionResult.error) {
    console.error("Nutrition fetch error", nutritionResult.error.message);
  }

  const context = buildUserContext(
    goalResult.data,
    metricResult.data,
    limitationResult.data ?? [],
    workoutResult.data,
    profileResult.error ? null : profileResult.data,
    analyticsResult.error ? null : analyticsResult.data,
    nutritionResult.error ? null : nutritionResult.data,
  );

  const { error: saveUserMessageError } = await supabase
    .from("ai_chat_messages")
    .insert({
      user_id: user.id,
      role: "user",
      content: message,
    });

  if (saveUserMessageError) {
    return new Response(
      JSON.stringify({
        error: "Failed to save user message.",
        details: saveUserMessageError.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const { data: recentMessages, error: recentMessagesError } = await supabase
    .from("ai_chat_messages")
    .select("role, content")
    .eq("user_id", user.id)
    .neq("role", "system")
    .order("created_at", { ascending: false })
    .limit(RECENT_MESSAGES_FETCH_LIMIT);

  if (recentMessagesError) {
    return new Response(
      JSON.stringify({
        error: "Failed to load recent messages.",
        details: recentMessagesError.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const cleanedMessages = mergeConsecutiveMessages(
    (recentMessages ?? []).slice().reverse().map((messageRow) => ({
      role: messageRow.role as string,
      content: messageRow.content as string,
    })),
  );
  const conversationMemory = optimizeConversationMemory(cleanedMessages);
  const systemPrompt = buildSystemPrompt(context, conversationMemory.summary);

  const geminiBody = {
    contents: toGeminiContents(conversationMemory.activeMessages),
    systemInstruction: {
      parts: [{ text: systemPrompt }],
    },
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 1024,
      topP: 0.95,
      responseMimeType: "application/json",
    },
  };

  let geminiData: any;

  try {
    geminiData = await requestGeminiWithRetry(
      buildGeminiGenerateContentUrl(geminiConfig),
      geminiBody,
    );
  } catch (error) {
    console.error("Gemini request error", {
      error: error instanceof Error ? error.message : String(error),
      userId: user.id,
    });

    const response = buildGeminiErrorResponse(error);
    return new Response(
      JSON.stringify(response.body),
      {
        status: response.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const rawReply = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!rawReply || typeof rawReply !== "string") {
    return new Response(
      JSON.stringify({
        error: "Gemini returned an empty response.",
      }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const structured = sanitizeCoachPayload(
    parseCoachResponse(rawReply),
    context,
  );

  if (!structured.reply.trim()) {
    return new Response(
      JSON.stringify({
        error: "Gemini returned an empty response.",
      }),
      {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const assistantContext = {
    ...context,
    interactive: {
      suggestions: structured.suggestions,
      actions: structured.actions,
    },
  };

  const { error: saveAssistantMessageError } = await supabase
    .from("ai_chat_messages")
    .insert({
      user_id: user.id,
      role: "assistant",
      content: structured.reply,
      context: assistantContext,
    });

  if (saveAssistantMessageError) {
    return new Response(
      JSON.stringify({
        error: "Failed to save assistant message.",
        details: saveAssistantMessageError.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      reply: structured.reply,
      suggestions: structured.suggestions,
      actions: structured.actions,
      provider: "gemini",
      model: geminiConfig.model,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});

async function checkUsageLimits(supabase: ReturnType<typeof createAuthorizedSupabaseClient>, userId: string) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const [dailyCountResult, latestMessageResult] = await Promise.all([
    supabase
      .from("ai_chat_messages")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("role", "user")
      .gte("created_at", today.toISOString()),
    supabase
      .from("ai_chat_messages")
      .select("created_at")
      .eq("user_id", userId)
      .eq("role", "user")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);

  if (dailyCountResult.error || latestMessageResult.error) {
    console.error("Usage limit check failed", {
      dailyCountError: dailyCountResult.error?.message,
      latestMessageError: latestMessageResult.error?.message,
      userId,
    });

    return {
      allowed: false,
      status: 500,
      error: "İstek limiti kontrol edilirken bir sorun oluştu. Lütfen tekrar deneyin.",
    };
  }

  if ((dailyCountResult.count ?? 0) >= MAX_USER_MESSAGES_PER_DAY) {
    return {
      allowed: false,
      status: 429,
      error: "Günlük AI koç limitine ulaşıldı. Lütfen yarın tekrar deneyin.",
    };
  }

  const latestCreatedAt = latestMessageResult.data?.created_at;
  if (typeof latestCreatedAt === "string") {
    const secondsSinceLastMessage =
      (Date.now() - new Date(latestCreatedAt).getTime()) / 1000;

    if (secondsSinceLastMessage < MIN_SECONDS_BETWEEN_MESSAGES) {
      return {
        allowed: false,
        status: 429,
        error: "Çok hızlı mesaj gönderiyorsun. Lütfen birkaç saniye bekleyip tekrar dene.",
      };
    }
  }

  return { allowed: true, status: 200, error: "" };
}

async function requestGeminiWithRetry(url: string, body: Record<string, unknown>) {
  let lastError: unknown;

  for (let attempt = 0; attempt <= GEMINI_MAX_RETRIES; attempt++) {
    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(GEMINI_TIMEOUT_MS),
      });

      if (response.ok) {
        return await response.json();
      }

      const errorText = await response.text();
      lastError = new GeminiHttpError(response.status, errorText);

      if (RETRYABLE_STATUS_CODES.has(response.status) && attempt < GEMINI_MAX_RETRIES) {
        await delay((attempt + 1) * 1500);
        continue;
      }

      throw lastError;
    } catch (error) {
      lastError = error;
      const isRetryableNetworkError =
        error instanceof DOMException ||
        (error instanceof Error &&
          (error.message.toLowerCase().includes("network") ||
            error.message.toLowerCase().includes("timeout") ||
            error.message.toLowerCase().includes("fetch")));

      if (isRetryableNetworkError && attempt < GEMINI_MAX_RETRIES) {
        await delay((attempt + 1) * 1500);
        continue;
      }

      throw error;
    }
  }

  throw lastError ?? new Error("Unknown Gemini request error");
}

function buildGeminiErrorResponse(error: unknown) {
  if (error instanceof GeminiHttpError) {
    if (error.status === 429) {
      return {
        status: 429,
        body: {
          error: "AI koç şu anda yoğun. Biraz bekleyip tekrar deneyin.",
        },
      };
    }

    if ([500, 502, 503, 504].includes(error.status)) {
      return {
        status: 503,
        body: {
          error: "AI servisi geçici olarak kullanılamıyor. Birkaç saniye sonra tekrar deneyin.",
        },
      };
    }

    return {
      status: 502,
      body: {
        error: "AI yanıtı alınamadı. Lütfen tekrar deneyin.",
      },
    };
  }

  if (error instanceof DOMException) {
    return {
      status: 504,
      body: {
        error: "AI isteği zaman aşımına uğradı. Lütfen tekrar deneyin.",
      },
    };
  }

  return {
    status: 500,
    body: {
      error: "Beklenmeyen bir AI hatası oluştu. Lütfen tekrar deneyin.",
    },
  };
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class GeminiHttpError extends Error {
  constructor(public status: number, public details: string) {
    super(`Gemini request failed with status ${status}`);
  }
}

function mergeConsecutiveMessages(messages: Array<{ role: string; content: string }>) {
  const merged: Array<{ role: string; content: string }> = [];

  for (const message of messages) {
    const last = merged.at(-1);
    if (last && last.role === message.role) {
      last.content = `${last.content}\n${message.content}`;
      continue;
    }

    merged.push({ ...message });
  }

  return merged;
}

function optimizeConversationMemory(messages: Array<{ role: string; content: string }>) {
  if (messages.length === 0) {
    return {
      activeMessages: [],
      summary: null,
    };
  }

  let keptCount = 0;
  let keptChars = 0;
  let windowStartIndex = messages.length;

  for (let i = messages.length - 1; i >= 0; i--) {
    const messageLength = messages[i].content.length;
    const exceedsBudget = keptChars + messageLength > ACTIVE_MEMORY_CHAR_BUDGET;
    const exceedsCount = keptCount >= ACTIVE_MEMORY_MAX_MESSAGES;

    if ((exceedsBudget || exceedsCount) && keptCount >= ACTIVE_MEMORY_MIN_MESSAGES) {
      break;
    }

    keptCount += 1;
    keptChars += messageLength;
    windowStartIndex = i;
  }

  const olderMessages = messages.slice(0, windowStartIndex);
  const activeMessages = messages.slice(windowStartIndex);

  return {
    activeMessages,
    summary: buildConversationMemorySummary(olderMessages),
  };
}

function buildConversationMemorySummary(messages: Array<{ role: string; content: string }>) {
  if (messages.length === 0) return null;

  const recentUserMessages = messages
    .filter((message) => message.role === "user")
    .slice(-MEMORY_SUMMARY_USER_ITEMS);
  const recentAssistantMessages = messages
    .filter((message) => message.role === "assistant")
    .slice(-MEMORY_SUMMARY_ASSISTANT_ITEMS);

  const lines: string[] = ["KISA SOHBET HAFIZASI:"];

  if (recentUserMessages.length > 0) {
    lines.push("- Önceki kullanıcı talepleri:");
    for (const message of recentUserMessages) {
      lines.push(`  * ${compactMemoryText(message.content, 140)}`);
    }
  }

  if (recentAssistantMessages.length > 0) {
    lines.push("- Önceki koç yönlendirmesi:");
    for (const message of recentAssistantMessages) {
      lines.push(`  * ${compactMemoryText(message.content, 160)}`);
    }
  }

  if (lines.length === 1) return null;
  return lines.join("\n");
}

function compactMemoryText(text: string, maxLength: number) {
  const normalized = text.replace(/\s+/g, " ").trim();
  if (normalized.length <= maxLength) return normalized;

  const sentenceCutIndex = normalized.search(/[.!?]\s/);
  if (sentenceCutIndex > 40 && sentenceCutIndex < maxLength) {
    return normalized.slice(0, sentenceCutIndex + 1).trim();
  }

  return `${normalized.slice(0, maxLength - 3).trim()}...`;
}

function toGeminiContents(messages: Array<{ role: string; content: string }>) {
  const contents = messages
    .filter((message) => message.role !== "system")
    .map((message) => ({
      role: message.role === "assistant" ? "model" : "user",
      parts: [{ text: message.content }],
    }));

  if (contents.length > 0 && contents[0].role !== "user") {
    contents.unshift({
      role: "user",
      parts: [{ text: "Merhaba" }],
    });
  }

  return contents;
}

function buildUserContext(
  goal: any,
  metric: any,
  limitations: any[],
  workout: any,
  profile: any,
  analytics: any,
  nutrition: any,
) {
  const context: Record<string, unknown> = {};

  if (goal) {
    context.goal = {
      type: mapGoalType(goal.goal_type),
      experience: mapExperienceLevel(goal.experience_level),
      activity_level: mapActivityLevel(goal.activity_level),
      days_per_week: goal.workout_days_per_week,
      workout_days: goal.workout_days ?? [],
      program_weeks: goal.program_weeks ?? 6,
    };
  }

  if (metric) {
    const bmi = calculateBmi(metric.height, metric.weight);
    context.metrics = {
      height_cm: metric.height,
      weight_kg: metric.weight,
      body_fat_percentage: metric.body_fat_percentage,
      bmi: bmi ? bmi.toFixed(1) : null,
      bmi_category: bmi ? mapBmiCategory(bmi) : "Bilinmiyor",
    };
  }

  context.calories = buildCalorieContext(goal, metric, profile, analytics, nutrition);

  if (limitations.length > 0) {
    context.limitations = limitations.map((limitation) => ({
      body_part: limitation.body_part,
      type: limitation.limitation_type,
      severity: mapSeverity(limitation.severity),
      notes: limitation.notes,
    }));
    context.safety = buildSafetyContext(limitations);
  }

  if (workout) {
    const workoutContext = buildWorkoutContext(goal, workout);
    if (workoutContext) {
      context.workout = workoutContext;
    }
  }

  return context;
}

function buildSystemPrompt(context: Record<string, unknown>, memorySummary?: string | null) {
  const lines: string[] = [
    "Sen PhysioFit uygulamasının AI fitness antrenörüsün.",
    'Adın "PhysioFit Koç".',
    "",
    "KURALLAR:",
    "- Türkçe yanıt ver.",
    "- Kısa, net ve motive edici ol.",
    "- Tıbbi teşhis veya tedavi önerme, gerekirse doktora yönlendir.",
    "- Kullanıcının hedefine, fiziksel durumuna ve kısıtlamalarına göre kişiselleştirilmiş öneriler ver.",
    "- Egzersiz formu, beslenme, dinlenme ve motivasyonu birlikte düşün.",
    "- Kısıtlı bölgelere zarar verebilecek hareketleri önermemeye dikkat et.",
    "",
  ];

  const goal = context.goal as Record<string, unknown> | undefined;
  const metrics = context.metrics as Record<string, unknown> | undefined;
  const limitations = context.limitations as Array<Record<string, unknown>> | undefined;
  const safety = context.safety as Record<string, unknown> | undefined;
  const calories = context.calories as Record<string, unknown> | undefined;

  if (goal || metrics || limitations?.length || calories) {
    lines.push("KULLANICI PROFİLİ:");
  }

  if (goal) {
    lines.push(`- Hedef: ${goal.type}`);
    lines.push(`- Deneyim: ${goal.experience}`);
    lines.push(`- Haftalık antrenman: ${goal.days_per_week} gün`);
    lines.push(`- Program süresi: ${goal.program_weeks} hafta`);
  }

  if (metrics) {
    if (metrics.height_cm != null) lines.push(`- Boy: ${metrics.height_cm} cm`);
    if (metrics.weight_kg != null) lines.push(`- Kilo: ${metrics.weight_kg} kg`);
    if (metrics.bmi != null) lines.push(`- BMI: ${metrics.bmi} (${metrics.bmi_category})`);
  }

  if (limitations && limitations.length > 0) {
    lines.push("- Kısıtlamalar:");
    for (const limitation of limitations) {
      lines.push(
        `  * ${limitation.body_part} - ${limitation.type} (${limitation.severity})`,
      );
    }
  }

  if (safety) {
    lines.push("- Güvenlik profili:");
    lines.push(`  * Genel risk: ${safety.overall_risk}`);
    lines.push(`  * Korumalı mod: ${safety.protective_mode ? "Açık" : "Kapalı"}`);
    const riskyCategories = safety.risky_categories as string[] | undefined;
    if (riskyCategories && riskyCategories.length > 0) {
      lines.push(`  * Kaçınılacak kategoriler: ${riskyCategories.join(", ")}`);
    }
    const riskyMuscles = safety.risky_muscle_groups as string[] | undefined;
    if (riskyMuscles && riskyMuscles.length > 0) {
      lines.push(`  * Riskli kas grupları: ${riskyMuscles.join(", ")}`);
    }
    const riskyPatterns = safety.risky_movement_patterns as string[] | undefined;
    if (riskyPatterns && riskyPatterns.length > 0) {
      lines.push(`  * Kaçınılacak hareket tipleri: ${riskyPatterns.join(", ")}`);
    }
  }

  const workout = context.workout as Record<string, unknown> | undefined;
  if (workout) {
    lines.push("- Aktif antrenman planı:");
    lines.push(`  * Plan adı: ${workout.name}`);
    lines.push(`  * Toplam egzersiz: ${workout.total_exercises}`);
    lines.push(`  * Plan süresi: ${workout.weeks} hafta`);
    lines.push(`  * Bugün antrenman günü mü: ${workout.is_workout_day ? "Evet" : "Hayır"}`);
    if (workout.today_focus != null) {
      lines.push(`  * Bugünkü odak: ${workout.today_focus}`);
    }
    const todayExercises = workout.today_exercises as Array<Record<string, unknown>> | undefined;
    if (todayExercises && todayExercises.length > 0) {
      lines.push("- Bugünkü egzersizler (exercise_id ile birlikte):");
      for (const exercise of todayExercises) {
        const sets = exercise.sets ?? "-";
        const reps = exercise.reps ?? "-";
        const rest = exercise.rest_seconds ?? "-";
        const exerciseId = exercise.exercise_id ?? "-";
        lines.push(
          `  * ${exercise.name} [id:${exerciseId}] | ${sets} set x ${reps} tekrar | dinlenme: ${rest} sn`,
        );
      }
    }
  }

  if (calories) {
    lines.push("- Günlük kalori özeti:");
    if (calories.available) {
      lines.push(`  * Günlük hedef (tahmini): ${calories.daily_target_kcal} kcal`);
      lines.push(`  * Bugün yakılan (tahmini): ${calories.burned_today_kcal} kcal`);
      if (calories.consumed_logged) {
        lines.push(`  * Bugün alınan (kullanıcı girişi): ${calories.consumed_today_kcal} kcal`);
        lines.push(`  * Kalan bütçe: ${calories.remaining_budget_kcal} kcal`);
      } else {
        lines.push("  * Bugün alınan: kullanıcı henüz giriş yapmadı");
        lines.push(
          `  * Hedef + yakılan ile teorik üst sınır: ${calories.theoretical_max_kcal} kcal`,
        );
      }
      lines.push(`  * Not: ${calories.note}`);
    } else {
      lines.push(`  * Veri eksik: ${calories.reason}`);
      lines.push("  * Beslenme önerirken genel, hedefe uygun tavsiyeler ver.");
    }
  }

  if (memorySummary) {
    lines.push("");
    lines.push(memorySummary);
  }

  lines.push("");
  lines.push("SENARYO BAZLI DAVRANIŞ:");
  lines.push("- Önce kullanıcının son mesajındaki ana niyeti belirle ve cevabı buna göre kur.");
  lines.push("- Birden fazla niyet varsa önce güvenlik, sonra antrenman, sonra beslenme/motivasyon kısmını ele al.");
  lines.push("");
  lines.push("1) BUGÜN NE YAPMALIYIM / BUGÜNKÜ ANTRENMAN");
  lines.push("- Aktif plan ve bugünkü egzersizler varsa önceliği bunlara ver.");
  lines.push("- Bugün antrenman günü değilse bunu açıkça söyle; gerekirse hafif yürüyüş, mobilite veya esneme öner.");
  lines.push("- Bugünkü egzersizleri yeniden yazarken gereksiz uzun plan çıkarma; en önemli sırayı ve dikkat noktalarını ver.");
  lines.push("");
  lines.push("2) HAREKET AĞRITIYOR / SAKATLIK / GÜVENLİK");
  lines.push("- Tıbbi teşhis koyma.");
  lines.push("- Ağrı, batma, uyuşma, şişlik veya hareket sırasında belirgin kötüleşme varsa hareketi durdurmasını söyle.");
  lines.push("- Mümkünse daha düşük riskli alternatif, yoğunluk azaltma veya dinlenme öner.");
  lines.push("- Belirsizlik varsa tek bir kısa netleştirici soru sor.");
  lines.push("- Kullanıcının kısıtlı bölgesiyle çakışan yüklenme, zorlama, patlayıcı tekrar veya yüksek hacim önermemelisin.");
  lines.push("- Mevcut plan ile güvenlik profili çelişirse planı savunma; açıkça azalt, değiştir veya pas geç.");
  lines.push("");
  lines.push("3) PLANI DEĞİŞTİR / ANTRENMAN KAÇIRILDI / İLERLEME DURDU");
  lines.push("- Mevcut planı tamamen sil baştan yazma; önce en küçük etkili düzenlemeyi öner.");
  lines.push("- Kaçırılan antrenmanlarda cezalandırıcı telafi planı verme.");
  lines.push("- Kullanıcının haftalık antrenman gününe ve program süresine uygun kal.");
  lines.push("");
  lines.push("4) BESLENME / TOPARLANMA");
  lines.push("- Hedefe uygun, temel ve güvenli öneriler ver.");
  lines.push("- Günlük kalori özeti mevcutsa önerilerini bu sayılara göre kişiselleştir.");
  lines.push("- Kalan bütçe düşükse hafif protein ağırlıklı öğün öner; yüksekse aşırı telafi yeme önerme.");
  lines.push("- Protein, su, uyku, dinlenme ve günlük rutin gibi uygulanabilir maddelere öncelik ver.");
  lines.push("- Katı tıbbi beslenme planı veya hastalık tedavisi verme.");
  lines.push("");
  lines.push("5) MOTİVASYON / DEVAMLILIK");
  lines.push("- Kısa, doğal ve destekleyici ol.");
  lines.push("- Kullanıcıyı bunaltmadan hemen uygulanacak tek bir sonraki adım öner.");
  lines.push("");
  lines.push("6) BELİRSİZ SORU");
  lines.push("- Kullanıcının amacı net değilse uzun tahminler yapma.");
  lines.push("- Önce tek bir açıklayıcı soru sor ve sonra yönlendir.");

  lines.push("");
  lines.push("YANIT FORMATI (ZORUNLU):");
  lines.push("- Yanıtını YALNIZCA geçerli JSON olarak ver.");
  lines.push("- JSON şeması:");
  lines.push(`  {
    "reply": "Kullanıcıya görünen Türkçe metin",
    "suggestions": ["Takip sorusu 1", "Takip sorusu 2"],
    "actions": [
      { "type": "open_workout", "label": "Bugünkü antrenmana git" },
      { "type": "open_exercise", "label": "Egzersiz videosunu aç", "exerciseId": "context-id" },
      { "type": "send_message", "label": "Kısa etiket", "message": "Gönderilecek tam soru" }
    ]
  }`);
  lines.push("- reply: kısa, net Türkçe; en fazla 8 satır; bölüm başlıkları kullanılabilir (Bugün, Önerim, Dikkat, Beslenme, Sonraki Adım).");
  lines.push("- suggestions: en fazla 3 kısa takip sorusu.");
  lines.push("- actions: en fazla 2 adet; yalnızca gerçekten faydalıysa ekle.");
  lines.push("- open_workout: yalnızca bugün antrenman günüyse ve aktif plan varsa.");
  lines.push("- open_exercise: yalnızca bugünkü egzersizler listesindeki exercise_id değerini kullan.");
  lines.push("- send_message: kullanıcının tek dokunuşla sorabileceği hazır mesaj.");
  lines.push("- JSON dışında hiçbir metin yazma.");

  if (safety) {
    lines.push("");
    lines.push("SERT GÜVENLİK KURALLARI:");
    lines.push("- Güvenlik kuralları, performans ve motivasyondan daha önceliklidir.");
    lines.push("- Yüksek risk veya korumalı mod varsa ağırlık artırma, failure'a gitme, patlayıcı tekrar ve agresif progresyon önerme.");
    lines.push("- 'Ameliyat' veya 'ağır' kısıtlama varsa yeni yoğun program yazma; yalnızca çok temkinli yönlendirme, dinlenme, düşük etkili alternatif veya uzman kontrolü öner.");
    lines.push("- Kullanıcı ağrılı bölgeyi çalıştırmakta ısrar etse bile doğrudan onay verme.");
    lines.push("- Riskli kategorileri ve riskli hareket tiplerini öneri dışında tut.");
  }

  if ((goal?.type as string | undefined) === "Fizyoterapi") {
    lines.push("");
    lines.push("FİZYOTERAPİ ODAĞI:");
    lines.push("- Öncelik güvenli hareket, kontrollü yüklenme ve semptom takibidir.");
    lines.push("- Performans artışı yerine ağrısız aralık, hareket kalitesi ve düzenli toparlanmayı öne çıkar.");
  }

  return lines.join("\n");
}

function buildWorkoutContext(goal: any, workout: any) {
  const exercises = Array.isArray(workout.exercises) ? workout.exercises : [];
  const workoutDays = Array.isArray(goal?.workout_days) ? goal.workout_days : [];
  const todayWeekday = new Date().getDay() === 0 ? 7 : new Date().getDay();
  const isWorkoutDay = workoutDays.length > 0
    ? workoutDays.includes(todayWeekday)
    : true;

  let todayExercises: any[] = [];

  if (workoutDays.length > 0) {
    const sortedDays = [...workoutDays].sort((a, b) => a - b);
    const dayIndex = sortedDays.indexOf(todayWeekday);
    if (dayIndex !== -1) {
      const exercisesPerDay = Math.ceil(exercises.length / sortedDays.length);
      const startIndex = dayIndex * exercisesPerDay;
      todayExercises = exercises.slice(startIndex, startIndex + exercisesPerDay);
    }
  } else {
    const daysPerWeek = goal?.workout_days_per_week ?? 3;
    const exercisesPerDay = daysPerWeek > 0
      ? Math.ceil(exercises.length / daysPerWeek)
      : exercises.length;
    const dayIndex = daysPerWeek > 0 ? (todayWeekday - 1) % daysPerWeek : 0;
    const startIndex = dayIndex * exercisesPerDay;
    todayExercises = exercises.slice(startIndex, startIndex + exercisesPerDay);
  }

  return {
    workout_id: workout.id,
    name: workout.name,
    weeks: workout.weeks ?? goal?.program_weeks ?? 6,
    total_exercises: exercises.length,
    is_workout_day: isWorkoutDay,
    today_focus: extractWorkoutFocus(todayExercises),
    today_exercises: todayExercises.map((exercise: any) => ({
      exercise_id: exercise.exercise_id ?? null,
      name: exercise.exercise_name ?? "Bilinmeyen egzersiz",
      sets: exercise.sets,
      reps: exercise.reps,
      rest_seconds: exercise.rest_seconds,
      notes: exercise.notes,
    })),
  };
}

type CoachAction = {
  type: string;
  label: string;
  exerciseId?: string;
  workoutId?: string;
  message?: string;
};

type StructuredCoachPayload = {
  reply: string;
  suggestions: string[];
  actions: CoachAction[];
};

function parseCoachResponse(raw: string): StructuredCoachPayload {
  const fallback = (reply: string): StructuredCoachPayload => ({
    reply: reply.trim(),
    suggestions: [],
    actions: [],
  });

  let jsonText = raw.trim();
  if (jsonText.startsWith("```")) {
    jsonText = jsonText.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
  }

  try {
    const parsed = JSON.parse(jsonText);
    const reply = typeof parsed.reply === "string" ? parsed.reply.trim() : "";
    const suggestions = Array.isArray(parsed.suggestions)
      ? parsed.suggestions.filter((item: unknown) => typeof item === "string").map((item: string) => item.trim())
      : [];
    const actions = Array.isArray(parsed.actions)
      ? parsed.actions
        .filter((item: unknown) => item && typeof item === "object")
        .map((item: Record<string, unknown>) => ({
          type: String(item.type ?? "").trim(),
          label: String(item.label ?? "").trim(),
          exerciseId: typeof item.exerciseId === "string"
            ? item.exerciseId
            : typeof item.exercise_id === "string"
            ? item.exercise_id
            : undefined,
          workoutId: typeof item.workoutId === "string"
            ? item.workoutId
            : typeof item.workout_id === "string"
            ? item.workout_id
            : undefined,
          message: typeof item.message === "string" ? item.message.trim() : undefined,
        }))
      : [];

    if (!reply) {
      return fallback(raw);
    }

    return { reply, suggestions, actions };
  } catch (_) {
    return fallback(raw);
  }
}

function sanitizeCoachPayload(
  payload: StructuredCoachPayload,
  context: Record<string, unknown>,
): StructuredCoachPayload {
  const workout = context.workout as Record<string, unknown> | undefined;
  const allowedExerciseIds = collectAllowedExerciseIds(workout);
  const workoutId = typeof workout?.workout_id === "string" ? workout.workout_id : undefined;
  const canOpenWorkout = workout?.is_workout_day === true && !!workoutId;

  const suggestions = payload.suggestions
    .filter((item) => item.length > 0)
    .slice(0, 3);

  const actions: CoachAction[] = [];

  for (const action of payload.actions) {
    if (actions.length >= 2) break;

    switch (action.type) {
      case "open_workout":
        if (canOpenWorkout) {
          actions.push({
            type: "open_workout",
            label: action.label || "Bugünkü antrenmana git",
            workoutId,
          });
        }
        break;
      case "open_exercise":
        if (action.exerciseId && allowedExerciseIds.has(action.exerciseId)) {
          actions.push({
            type: "open_exercise",
            label: action.label || "Egzersizi aç",
            exerciseId: action.exerciseId,
          });
        }
        break;
      case "send_message":
        if (action.message && action.message.trim().length > 0) {
          actions.push({
            type: "send_message",
            label: action.label || "Devam et",
            message: action.message.trim(),
          });
        }
        break;
    }
  }

  return {
    reply: payload.reply.trim(),
    suggestions,
    actions,
  };
}

function collectAllowedExerciseIds(workout: Record<string, unknown> | undefined) {
  const ids = new Set<string>();
  if (!workout) return ids;

  const todayExercises = workout.today_exercises;
  if (Array.isArray(todayExercises)) {
    for (const exercise of todayExercises) {
      if (exercise && typeof exercise === "object") {
        const exerciseId = (exercise as Record<string, unknown>).exercise_id;
        if (typeof exerciseId === "string" && exerciseId.trim().length > 0) {
          ids.add(exerciseId);
        }
      }
    }
  }

  return ids;
}

function buildSafetyContext(limitations: any[]) {
  const riskyMuscleGroups = new Set<string>();
  const riskyCategories = new Set<string>();
  const riskyMovementPatterns = new Set<string>();
  let highestSeverityScore = 0;
  let protectiveMode = false;

  for (const limitation of limitations) {
    const bodyPart = normalizeBodyPart(limitation.body_part);
    const severity = String(limitation.severity ?? "").toLowerCase();
    const limitationType = String(limitation.limitation_type ?? "").toLowerCase();
    const severityScore = getSeverityScore(severity);

    highestSeverityScore = Math.max(highestSeverityScore, severityScore);
    if (severity === "high" || limitationType === "ameliyat") {
      protectiveMode = true;
    }

    for (const category of getRiskyCategoriesForBodyPart(bodyPart, severity)) {
      riskyCategories.add(category);
    }
    for (const muscle of getRiskyMuscleGroupsForBodyPart(bodyPart)) {
      riskyMuscleGroups.add(muscle);
    }
    for (const pattern of getRiskyMovementPatterns(bodyPart, limitationType, severity)) {
      riskyMovementPatterns.add(pattern);
    }
  }

  return {
    overall_risk: mapSafetyRisk(highestSeverityScore),
    protective_mode: protectiveMode,
    risky_categories: Array.from(riskyCategories),
    risky_muscle_groups: Array.from(riskyMuscleGroups),
    risky_movement_patterns: Array.from(riskyMovementPatterns),
  };
}

function getSeverityScore(severity: string) {
  switch (severity) {
    case "high":
      return 3;
    case "medium":
      return 2;
    case "low":
      return 1;
    default:
      return 0;
  }
}

function mapSafetyRisk(score: number) {
  switch (score) {
    case 3:
      return "Yüksek";
    case 2:
      return "Orta";
    case 1:
      return "Düşük";
    default:
      return "Belirsiz";
  }
}

function normalizeBodyPart(value: string | null | undefined) {
  const normalized = String(value ?? "").trim().toLowerCase();
  if (normalized === "kalca") return "kalça";
  if (normalized === "ayak bilegi") return "ayak bileği";
  return normalized;
}

function getRiskyCategoriesForBodyPart(bodyPart: string, severity: string) {
  const isHigh = severity === "high";
  switch (bodyPart) {
    case "diz":
      return isHigh ? ["legs"] : [];
    case "omuz":
      return isHigh ? ["shoulders"] : [];
    case "bel":
      return isHigh ? ["back"] : [];
    case "dirsek":
      return isHigh ? ["arms"] : [];
    default:
      return [];
  }
}

function getRiskyMuscleGroupsForBodyPart(bodyPart: string) {
  switch (bodyPart) {
    case "diz":
      return ["quadriceps", "hamstrings"];
    case "omuz":
      return ["shoulders"];
    case "bel":
      return ["back"];
    case "kalça":
      return ["glutes", "hamstrings"];
    case "dirsek":
      return ["biceps", "triceps", "forearms"];
    case "ayak bileği":
      return ["calves"];
    default:
      return [];
  }
}

function getRiskyMovementPatterns(bodyPart: string, limitationType: string, severity: string) {
  const patterns = new Set<string>();
  const isHigh = severity === "high";

  switch (bodyPart) {
    case "diz":
      patterns.add("derin squat/lunge");
      patterns.add("zıplama ve koşu");
      break;
    case "omuz":
      patterns.add("baş üstü press");
      patterns.add("geniş açılı itiş/çekiş");
      break;
    case "bel":
      patterns.add("ağır hinge ve ağır row");
      patterns.add("ani rotasyon");
      break;
    case "kalça":
      patterns.add("derin kalça fleksiyonu");
      patterns.add("tek taraflı patlayıcı alt vücut");
      break;
    case "dirsek":
      patterns.add("ağır curl/extension");
      patterns.add("kilitli itişler");
      break;
    case "ayak bileği":
      patterns.add("yüksek impact iniş");
      patterns.add("ani yön değişimi");
      break;
  }

  if (limitationType === "ameliyat") {
    patterns.add("agresif yük artışı");
    patterns.add("patlayıcı tekrar");
  }

  if (isHigh) {
    patterns.add("failure'a kadar set");
    patterns.add("yüksek hacim");
  }

  return Array.from(patterns);
}

function extractWorkoutFocus(exercises: any[]) {
  if (exercises.length === 0) return null;
  const note = exercises[0]?.notes;
  if (typeof note === "string" && note.trim().length > 0) {
    const parts = note.split("-");
    return parts[0]?.trim() ?? note.trim();
  }
  return "Genel antrenman";
}

function calculateBmi(height: number | null, weight: number | null) {
  if (!height || !weight || height <= 0) return null;
  const heightInMeters = height / 100;
  return weight / (heightInMeters * heightInMeters);
}

function mapGoalType(goalType: string) {
  switch (goalType) {
    case "weight_loss":
      return "Kilo Verme";
    case "muscle_gain":
      return "Kas Yapma";
    case "physiotherapy":
      return "Fizyoterapi";
    case "general_fitness":
      return "Genel Fitness";
    default:
      return goalType;
  }
}

function mapExperienceLevel(level: string) {
  switch (level) {
    case "beginner":
      return "Başlangıç";
    case "intermediate":
      return "Orta";
    case "advanced":
      return "İleri";
    default:
      return level;
  }
}

function mapSeverity(severity: string) {
  switch (severity) {
    case "low":
      return "Hafif";
    case "medium":
      return "Orta";
    case "high":
      return "Ağır";
    default:
      return severity;
  }
}

function mapBmiCategory(bmi: number) {
  if (bmi < 18.5) return "Zayıf";
  if (bmi < 25) return "Normal";
  if (bmi < 30) return "Fazla Kilolu";
  return "Obez";
}

function mapActivityLevel(level: string | null | undefined) {
  switch (level) {
    case "sedentary":
      return "Hareketsiz";
    case "light":
      return "Hafif Aktif";
    case "moderate":
      return "Orta Aktif";
    case "active":
      return "Aktif";
    case "very_active":
      return "Çok Aktif";
    default:
      return "Orta Aktif";
  }
}

function activityMultiplier(level: string | null | undefined) {
  switch (level) {
    case "sedentary":
      return 1.2;
    case "light":
      return 1.375;
    case "moderate":
      return 1.55;
    case "active":
      return 1.725;
    case "very_active":
      return 1.9;
    default:
      return 1.55;
  }
}

function calculateAge(birthDateStr: string) {
  const birth = new Date(birthDateStr);
  if (Number.isNaN(birth.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const monthDiff = now.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < birth.getDate())) {
    age -= 1;
  }
  return age > 0 ? age : null;
}

function calculateBmr(
  weightKg: number,
  heightCm: number,
  age: number,
  gender: string | null | undefined,
) {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  if (gender === "female") return base - 161;
  return base + 5;
}

function calculateDailyTargetKcal(
  weightKg: number,
  heightCm: number,
  age: number,
  gender: string | null | undefined,
  activityLevel: string | null | undefined,
  goalType: string | null | undefined,
) {
  const bmr = calculateBmr(weightKg, heightCm, age, gender);
  const tdee = bmr * activityMultiplier(activityLevel);

  if (goalType === "weight_loss") {
    return Math.min(5000, Math.max(1200, Math.round(tdee - 400)));
  }
  if (goalType === "muscle_gain") {
    return Math.min(6000, Math.max(1500, Math.round(tdee + 250)));
  }
  return Math.min(6000, Math.max(1200, Math.round(tdee)));
}

function buildCalorieContext(
  goal: any,
  metric: any,
  profile: any,
  analytics: any,
  nutrition: any,
) {
  const weight = metric?.weight;
  const height = metric?.height;
  const birthDate = profile?.birth_date;
  const gender = profile?.gender;

  if (!weight || !height || !birthDate) {
    return {
      available: false,
      reason: "Boy, kilo veya doğum tarihi eksik",
    };
  }

  const age = calculateAge(birthDate);
  if (!age) {
    return {
      available: false,
      reason: "Yaş hesaplanamadı",
    };
  }

  const dailyTarget = calculateDailyTargetKcal(
    Number(weight),
    Number(height),
    age,
    gender,
    goal?.activity_level,
    goal?.goal_type,
  );
  const burnedToday = Number(analytics?.calories_burned ?? 0);
  const consumedToday = Number(nutrition?.calories_consumed ?? 0);
  const consumedLogged = consumedToday > 0;
  const remainingBudget = dailyTarget + burnedToday - consumedToday;

  return {
    available: true,
    daily_target_kcal: dailyTarget,
    burned_today_kcal: burnedToday,
    consumed_today_kcal: consumedToday,
    consumed_logged: consumedLogged,
    remaining_budget_kcal: remainingBudget,
    theoretical_max_kcal: dailyTarget + burnedToday,
    note: "Yakılan değerler MET formülüyle tahminidir; alınan kalori kullanıcı girişidir.",
  };
}
