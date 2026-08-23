const MAX_ITEMS = 30;
const MAX_QUANTITY = 20;

function cleanText(value, maxLength) {
  return String(value || "").trim().slice(0, maxLength);
}

function validatePayload(body) {
  const customer = body && body.customer;
  const items = body && body.items;

  if (!customer || !Array.isArray(items) || items.length < 1 || items.length > MAX_ITEMS) {
    return "Invalid order payload";
  }

  if (!cleanText(customer.full_name, 120) || !cleanText(customer.phone, 30) ||
      !cleanText(customer.governorate, 80) || !cleanText(customer.address, 500)) {
    return "Customer name, phone, governorate and address are required";
  }

  const phone = cleanText(customer.phone, 30).replace(/[\s()-]/g, "");
  if (!/^\+?[0-9]{8,15}$/.test(phone)) {
    return "Invalid phone number";
  }

  for (const item of items) {
    const quantity = Number(item && item.quantity);
    if (!cleanText(item && item.product_ref, 120) || !Number.isInteger(quantity) || quantity < 1 || quantity > MAX_QUANTITY) {
      return "Invalid product or quantity";
    }
  }

  return "";
}

module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ error: "Method not allowed" });
  }

  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    return res.status(503).json({ error: "Order service is not configured" });
  }

  const validationError = validatePayload(req.body);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const payload = {
    customer: {
      full_name: cleanText(req.body.customer.full_name, 120),
      phone: cleanText(req.body.customer.phone, 30).replace(/[\s()-]/g, ""),
      governorate: cleanText(req.body.customer.governorate, 80),
      address: cleanText(req.body.customer.address, 500)
    },
    notes: cleanText(req.body.notes, 1000),
    discount_code: cleanText(req.body.discount_code, 50).toUpperCase(),
    items: req.body.items.map((item) => ({
      product_ref: cleanText(item.product_ref, 120),
      quantity: Number(item.quantity),
      selected_size: cleanText(item.selected_size, 40),
      selected_color: cleanText(item.selected_color, 100)
    }))
  };

  try {
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/place_order`, {
      method: "POST",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ p_payload: payload })
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error("Supabase order error", response.status, result);
      return res.status(400).json({ error: result.message || "Unable to create order" });
    }

    res.setHeader("Cache-Control", "no-store");
    return res.status(201).json(result);
  } catch (error) {
    console.error("Order API failure", error);
    return res.status(500).json({ error: "Unable to create order. Please try again." });
  }
};

