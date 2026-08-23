create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from public.admin_users a
    where a.user_id = auth.uid()
      and a.is_active = true
      and lower(a.email) in ('admin@moka.eg','drmohamed@moka.eg')
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.customers enable row level security;
alter table public.collections enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "public read active collections" on public.collections;
create policy "public read active collections" on public.collections
for select to anon, authenticated using (is_active or public.is_admin());

drop policy if exists "public read active products" on public.products;
create policy "public read active products" on public.products
for select to anon, authenticated using (is_active or public.is_admin());

drop policy if exists "public read active product images" on public.product_images;
create policy "public read active product images" on public.product_images
for select to anon, authenticated using (
  exists (select 1 from public.products p where p.id = product_id and (p.is_active or public.is_admin()))
);

drop policy if exists "admins manage collections" on public.collections;
create policy "admins manage collections" on public.collections
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins manage products" on public.products;
create policy "admins manage products" on public.products
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins manage product images" on public.product_images;
create policy "admins manage product images" on public.product_images
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins read customers" on public.customers;
create policy "admins read customers" on public.customers
for select to authenticated using (public.is_admin());

drop policy if exists "admins update customers" on public.customers;
create policy "admins update customers" on public.customers
for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins read orders" on public.orders;
create policy "admins read orders" on public.orders
for select to authenticated using (public.is_admin());

drop policy if exists "admins update orders" on public.orders;
create policy "admins update orders" on public.orders
for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins read order items" on public.order_items;
create policy "admins read order items" on public.order_items
for select to authenticated using (public.is_admin());

drop policy if exists "admin reads own allowlist row" on public.admin_users;
create policy "admin reads own allowlist row" on public.admin_users
for select to authenticated using (user_id = auth.uid() and is_active);

create or replace function public.place_order(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer jsonb := p_payload->'customer';
  v_items jsonb := p_payload->'items';
  v_customer_id bigint;
  v_order_id uuid := gen_random_uuid();
  v_order_number text := 'MOKA-' || lpad(nextval('public.moka_order_number_seq')::text, 6, '0');
  v_subtotal numeric(12,2) := 0;
  v_discount_amount numeric(12,2) := 0;
  v_total numeric(12,2) := 0;
  v_discount_code text := upper(btrim(coalesce(p_payload->>'discount_code','')));
  v_item jsonb;
  v_product public.products%rowtype;
  v_quantity integer;
  v_size text;
  v_color text;
  v_image text;
begin
  if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) < 1 or jsonb_array_length(v_items) > 30 then
    raise exception 'Cart must contain between 1 and 30 products';
  end if;

  if btrim(coalesce(v_customer->>'full_name','')) = '' or
     btrim(coalesce(v_customer->>'phone','')) = '' or
     btrim(coalesce(v_customer->>'governorate','')) = '' or
     btrim(coalesce(v_customer->>'address','')) = '' then
    raise exception 'Customer information is incomplete';
  end if;

  for v_item in select * from jsonb_array_elements(v_items)
  loop
    v_quantity := (v_item->>'quantity')::integer;
    if v_quantity < 1 or v_quantity > 20 then
      raise exception 'Invalid quantity';
    end if;

    select * into v_product
    from public.products
    where slug = v_item->>'product_ref' and is_active = true
    for share;

    if not found then
      raise exception 'Product % is unavailable', v_item->>'product_ref';
    end if;

    if v_product.stock_quantity is not null and v_product.stock_quantity < v_quantity then
      raise exception 'Insufficient stock for %', v_product.name;
    end if;

    v_size := btrim(coalesce(v_item->>'selected_size',''));
    v_color := btrim(coalesce(v_item->>'selected_color',''));

    if cardinality(v_product.available_sizes) > 0 and not (v_size = any(v_product.available_sizes)) then
      raise exception 'Invalid size for %', v_product.name;
    end if;
    if cardinality(v_product.available_colors) > 0 and not (v_color = any(v_product.available_colors)) then
      raise exception 'Invalid color for %', v_product.name;
    end if;

    v_subtotal := v_subtotal + (v_product.price * v_quantity);
  end loop;

  if v_discount_code = 'WELCMOKA' then
    v_discount_amount := round(v_subtotal * 0.10);
  else
    v_discount_code := '';
  end if;
  v_total := v_subtotal - v_discount_amount;

  select id into v_customer_id
  from public.customers
  where phone = btrim(v_customer->>'phone')
  limit 1;

  if v_customer_id is null then
    insert into public.customers(name, phone, governorate, address)
    values (
      btrim(v_customer->>'full_name'), btrim(v_customer->>'phone'),
      btrim(v_customer->>'governorate'), btrim(v_customer->>'address')
    ) returning id into v_customer_id;
  else
    update public.customers set
      name = btrim(v_customer->>'full_name'),
      governorate = btrim(v_customer->>'governorate'),
      address = btrim(v_customer->>'address'),
      updated_at = now()
    where id = v_customer_id;
  end if;

  insert into public.orders(
    id, order_number, customer_id, subtotal, discount_code, discount_amount, total_amount,
    status, notes, customer_name_snapshot, phone_snapshot, governorate_snapshot, address_snapshot
  ) values (
    v_order_id, v_order_number, v_customer_id, v_subtotal, v_discount_code, v_discount_amount, v_total,
    'pending', left(coalesce(p_payload->>'notes',''),1000), btrim(v_customer->>'full_name'),
    btrim(v_customer->>'phone'), btrim(v_customer->>'governorate'), btrim(v_customer->>'address')
  );

  for v_item in select * from jsonb_array_elements(v_items)
  loop
    v_quantity := (v_item->>'quantity')::integer;
    select * into v_product from public.products where slug = v_item->>'product_ref' and is_active = true;
    select image_url into v_image from public.product_images where product_id = v_product.id order by sort_order, created_at limit 1;

    insert into public.order_items(
      order_id, product_id, product_name_snapshot, product_image_snapshot,
      selected_size, selected_color, quantity, unit_price, subtotal
    ) values (
      v_order_id, v_product.id, v_product.name, coalesce(v_image,''),
      btrim(coalesce(v_item->>'selected_size','')), btrim(coalesce(v_item->>'selected_color','')),
      v_quantity, v_product.price, v_product.price * v_quantity
    );

    if v_product.stock_quantity is not null then
      update public.products set stock_quantity = stock_quantity - v_quantity where id = v_product.id;
    end if;
  end loop;

  return jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_number,
    'subtotal', v_subtotal,
    'discount_amount', v_discount_amount,
    'total_amount', v_total,
    'status', 'pending'
  );
end;
$$;

revoke all on function public.place_order(jsonb) from public, anon, authenticated;
grant execute on function public.place_order(jsonb) to service_role;

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "public read product images bucket" on storage.objects;
create policy "public read product images bucket" on storage.objects
for select to public using (bucket_id = 'product-images');

drop policy if exists "admins upload product images" on storage.objects;
create policy "admins upload product images" on storage.objects
for insert to authenticated with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "admins update product images" on storage.objects;
create policy "admins update product images" on storage.objects
for update to authenticated using (bucket_id = 'product-images' and public.is_admin())
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "admins delete product images" on storage.objects;
create policy "admins delete product images" on storage.objects
for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());

insert into public.admin_users(user_id, email)
select id, lower(email) from auth.users
where lower(email) in ('admin@moka.eg','drmohamed@moka.eg')
on conflict (user_id) do update set email = excluded.email, is_active = true;
