import { getSupabaseClient } from "./supabase-client.js";

async function loadCatalog() {
  try {
    const supabase = await getSupabaseClient();
    const { data, error } = await supabase
      .from("products")
      .select("id,slug,name,description,price,available_sizes,available_colors,stock_quantity,is_active,collection:collections(id,slug,name,description,image_url,sort_order),images:product_images(id,image_url,alt_text,sort_order)")
      .eq("is_active", true)
      .order("sort_order", { referencedTable: "product_images", ascending: true });

    if (error) throw error;
    if (Array.isArray(data) && data.length && typeof window.applySupabaseCatalog === "function") {
      window.applySupabaseCatalog(data);
    }
  } catch (error) {
    console.warn("Using local MOKA catalog fallback:", error.message);
  }
}

window.MokaBackend = {
  async placeOrder(payload) {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(payload)
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(result.error || "Unable to place order");
    return result;
  }
};

document.addEventListener("DOMContentLoaded", loadCatalog);

