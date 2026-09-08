-- PLANTEDEX — schéma Supabase (v2, idempotent)
-- À coller dans Supabase → SQL Editor → New query → Run
-- Peut être ré-exécuté sans risque si la v1 a déjà été lancée.

create extension if not exists "pgcrypto";

create table if not exists plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid, -- nullable pour la V1 sans authentification
  species_id text, -- clé stable (id d'espèce connue, ou id généré pour une plante perso)
  is_custom boolean not null default false, -- true si l'espèce n'est pas dans la bibliothèque locale
  perenual_id integer, -- id externe API Perenual, pour plus tard

  -- Champs descriptifs : uniquement remplis quand is_custom = true
  common_name text,
  scientific_name text,
  species_type text,
  emoji text,
  history text,
  watering text,
  light text,
  temperature text,
  soil text,
  soil_mix jsonb,
  humidity text,
  toxicity text,

  -- Données personnelles, toujours remplies
  photo_url text,
  gradient_top text,
  gradient_bottom text,
  size text,
  location text,
  date_added timestamptz not null default now(),
  last_watered timestamptz
);

-- Ajout idempotent des colonnes si la table existait déjà en v1
alter table plants add column if not exists species_id text;
alter table plants add column if not exists is_custom boolean not null default false;
alter table plants add column if not exists soil_mix jsonb;
create unique index if not exists plants_species_id_key on plants (species_id);

create table if not exists plant_care_log (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references plants(id) on delete cascade,
  action text not null,
  details text,
  created_at timestamptz not null default now()
);

alter table plants enable row level security;
alter table plant_care_log enable row level security;

drop policy if exists "Accès public en lecture/écriture (V1 sans auth)" on plants;
create policy "Accès public en lecture/écriture (V1 sans auth)"
  on plants for all
  using (true)
  with check (true);

drop policy if exists "Accès public en lecture/écriture (V1 sans auth)" on plant_care_log;
create policy "Accès public en lecture/écriture (V1 sans auth)"
  on plant_care_log for all
  using (true)
  with check (true);

-- ⚠️ Accès ouvert à tout le monde tant qu'il n'y a pas d'authentification.
-- À restreindre avec des policies filtrées sur user_id = auth.uid() une fois Supabase Auth activé.
