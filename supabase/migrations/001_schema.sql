-- MOKA core schema. This migration never drops or recreates public.customers.
create extension if not exists pgcrypto;

do $$
begin
  if to_regclass('public.customers') is null then
    raise exception 'public.customers must exist before running MOKA migrations';
  end if;
end $$;

-- Preserve the existing bigint identity id, name, email, address and created_at columns exactly.
-- Only add the customer fields required by the current checkout flow.
alter table public.customers add column if not exists phone text;
alter table public.customers add column if not exists governorate text;
alter table public.customers add column if not exists updated_at timestamptz default now();

do $$
declare
  id_type text;
  id_is_identity text;
begin
  select data_type, is_identity into id_type, id_is_identity
  from information_schema.columns
  where table_schema = 'public' and table_name = 'customers' and column_name = 'id';

  if id_type <> 'bigint' or id_is_identity <> 'YES' then
    raise exception 'Expected the preserved customers.id bigint identity column (found type %, identity %).', id_type, id_is_identity;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public' and t.relname = 'customers' and c.contype in ('p','u')
      and array_length(c.conkey, 1) = 1
      and (select attname from pg_attribute where attrelid = t.oid and attnum = c.conkey[1]) = 'id'
  ) then
    raise exception 'Existing customers.id must already have a primary-key or unique constraint so orders can reference it.';
  end if;
end $$;

create index if not exists customers_phone_idx
  on public.customers (phone) where phone is not null and btrim(phone) <> '';

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text not null default '',
  image_url text not null default '',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text not null default '',
  price numeric(12,2) not null check (price >= 0),
  collection_id uuid references public.collections(id) on delete set null,
  available_sizes text[] not null default '{}',
  available_colors text[] not null default '{}',
  is_active boolean not null default true,
  stock_quantity integer check (stock_quantity is null or stock_quantity >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  sort_order integer not null default 0,
  alt_text text not null default '',
  created_at timestamptz not null default now(),
  unique(product_id, image_url)
);

create sequence if not exists public.moka_order_number_seq start 1001;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  customer_id bigint not null references public.customers(id) on delete restrict,
  subtotal numeric(12,2) not null check (subtotal >= 0),
  discount_code text not null default '',
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  total_amount numeric(12,2) not null check (total_amount >= 0),
  status text not null default 'pending' check (status in ('pending','confirmed','processing','shipped','completed','cancelled')),
  notes text not null default '',
  customer_name_snapshot text not null,
  phone_snapshot text not null,
  governorate_snapshot text not null,
  address_snapshot text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  product_name_snapshot text not null,
  product_image_snapshot text not null default '',
  selected_size text not null default '',
  selected_color text not null default '',
  quantity integer not null check (quantity between 1 and 20),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (lower(email) in ('admin@moka.eg','drmohamed@moka.eg'))
);

create index if not exists products_collection_id_idx on public.products(collection_id);
create index if not exists products_active_idx on public.products(is_active);
create index if not exists product_images_product_id_idx on public.product_images(product_id, sort_order);
create index if not exists orders_customer_id_idx on public.orders(customer_id);
create index if not exists orders_created_at_idx on public.orders(created_at desc);
create index if not exists orders_status_idx on public.orders(status);
create index if not exists order_items_order_id_idx on public.order_items(order_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at before update on public.customers
for each row execute function public.set_updated_at();

drop trigger if exists collections_set_updated_at on public.collections;
create trigger collections_set_updated_at before update on public.collections
for each row execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at before update on public.orders
for each row execute function public.set_updated_at();
