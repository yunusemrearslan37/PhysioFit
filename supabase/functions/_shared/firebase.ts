declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
};

type FirebaseServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri: string;
};

type CachedAccessToken = {
  token: string;
  expiresAt: number;
};

let cachedAccessToken: CachedAccessToken | null = null;

export function getFirebaseRuntimeConfig(): FirebaseServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON secret is missing.");
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    throw new Error(
      `FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  }

  const projectId = String(parsed.project_id ?? "").trim();
  const clientEmail = String(parsed.client_email ?? "").trim();
  const privateKey = String(parsed.private_key ?? "").replace(/\\n/g, "\n").trim();
  const tokenUri = String(parsed.token_uri ?? "https://oauth2.googleapis.com/token").trim();

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error("Firebase service account JSON is missing required fields.");
  }

  return {
    project_id: projectId,
    client_email: clientEmail,
    private_key: privateKey,
    token_uri: tokenUri,
  };
}

export async function getFirebaseAccessToken(
  config: FirebaseServiceAccount,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) {
    return cachedAccessToken.token;
  }

  const jwt = await createSignedJwt(config, now);
  const response = await fetch(config.token_uri, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(
      `Failed to fetch Firebase access token: ${JSON.stringify(payload)}`,
    );
  }

  const accessToken = String(payload.access_token ?? "");
  const expiresIn = Number(payload.expires_in ?? 3600);
  if (!accessToken) {
    throw new Error("Firebase access token response did not include access_token.");
  }

  cachedAccessToken = {
    token: accessToken,
    expiresAt: now + expiresIn,
  };

  return accessToken;
}

export async function sendFirebasePushMessage(
  config: FirebaseServiceAccount,
  message: Record<string, unknown>,
) {
  const accessToken = await getFirebaseAccessToken(config);
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${config.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    },
  );

  const text = await response.text();
  let payload: Record<string, unknown> | null = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch (_) {
    payload = { raw: text };
  }

  if (!response.ok) {
    throw new Error(
      `Firebase send failed with ${response.status}: ${JSON.stringify(payload)}`,
    );
  }

  return payload;
}

async function createSignedJwt(
  config: FirebaseServiceAccount,
  now: number,
): Promise<string> {
  const header = base64UrlEncodeJson({
    alg: "RS256",
    typ: "JWT",
  });

  const payload = base64UrlEncodeJson({
    iss: config.client_email,
    sub: config.client_email,
    aud: config.token_uri,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    iat: now,
    exp: now + 3600,
  });

  const unsignedToken = `${header}.${payload}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(config.private_key),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedToken),
  );

  return `${unsignedToken}.${base64UrlEncodeBytes(new Uint8Array(signature))}`;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");

  const binary = atob(normalized);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return bytes.buffer;
}

function base64UrlEncodeJson(value: Record<string, unknown>) {
  return base64UrlEncodeBytes(
    new TextEncoder().encode(JSON.stringify(value)),
  );
}

function base64UrlEncodeBytes(bytes: Uint8Array) {
  const base64 = btoa(String.fromCharCode(...bytes));
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
