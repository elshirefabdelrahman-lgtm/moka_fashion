module.exports = async function handler(req, res) {
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    return res.status(405).json({ error: "Method not allowed" });
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    return res.status(503).json({ error: "Supabase public configuration is missing" });
  }

  res.setHeader("Cache-Control", "public, max-age=300, s-maxage=300");
  return res.status(200).json({ supabaseUrl, supabaseAnonKey });
};

