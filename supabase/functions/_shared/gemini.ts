export type GeminiRuntimeConfig = {
  apiKey: string;
  model: string;
};

const DEFAULT_GEMINI_MODEL = "gemini-2.5-flash";

export function getGeminiRuntimeConfig(): GeminiRuntimeConfig {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  const model = Deno.env.get("GEMINI_MODEL") ?? DEFAULT_GEMINI_MODEL;

  if (!apiKey || apiKey.trim().length === 0) {
    throw new Error("GEMINI_API_KEY secret is missing.");
  }

  return {
    apiKey,
    model,
  };
}

export function buildGeminiGenerateContentUrl(config: GeminiRuntimeConfig): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}`;
}
