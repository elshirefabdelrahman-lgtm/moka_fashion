import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

let clientPromise;

export async function getSupabaseClient() {
  if (!clientPromise) {
    clientPromise = fetch("/api/config", { headers: { Accept: "application/json" } })
      .then(async (response) => {
        const config = await response.json();
        if (!response.ok || !config.supabaseUrl || !config.supabaseAnonKey) {
          throw new Error(config.error || "Supabase configuration is unavailable");
        }
        return createClient(config.supabaseUrl, config.supabaseAnonKey, {
          auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
        });
      });
  }
  return clientPromise;
}

