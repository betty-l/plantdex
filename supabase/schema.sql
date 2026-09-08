-- PLANTEDEX — schéma Supabase
-- À coller dans Supabase → SQL Editor → New query → Run

-- Extension nécessaire pour générer des UUID
create extension if not exists "pgcrypto";

-- Table principale : les plantes de la collection personnelle
create table if not exists plants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid, -- laissé nullable pour la V1 sans authentification ; sera lié à auth.users plus tard
  perenual_id integer, -- id externe API Perenual, pour plus tard
  common_name text not null,
  scientific_name text,
  species_type text, -- ex: "Aroïde", "Succulente"...
  emoji text, -- icône de repli si pas de photo
  photo_url text, -- URL publique dans le bucket Storage
  gradient_top text, -- couleur du dégradé calculée depuis la photo
  gradient_bottom text,
  size text, -- "Petite" / "Moyenne" / "Grande"
  location text, -- ex: "Salon, près de la fenêtre"
  history text,
  watering text,
  light text,
  temperature text,
  soil text,
  humidity text,
  toxicity text,
  date_added timestamptz not null default now(),
  last_watered timestamptz
);

-- Historique d'entretien
create table if not exists plant_care_log (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references plants(id) on delete cascade,
  action text not null, -- "Ajoutée à la collection" / "Photo mise à jour" / etc.
  details text,
  created_at timestamptz not null default now()
);

-- Row Level Security : activée par défaut, mais accès libre en V1 (pas encore de comptes utilisateurs)
alter table plants enable row level security;
alter table plant_care_log enable row level security;

create policy "Accès public en lecture/écriture (V1 sans auth)"
  on plants for all
  using (true)
  with check (true);

create policy "Accès public en lecture/écriture (V1 sans auth)"
  on plant_care_log for all
  using (true)
  with check (true);

-- ⚠️ Ces policies ouvrent l'accès à tout le monde tant qu'il n'y a pas d'authentification.
-- Le jour où Supabase Auth est activé, on les remplacera par des règles filtrées sur user_id = auth.uid().
