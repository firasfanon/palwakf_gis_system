-- v5_core_history_and_lands.sql
-- Safe migration: creates missing history + lands tables/types used by Flutter v5 code.
-- Designed to be re-runnable (IF NOT EXISTS / guarded DO blocks).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0) Extensions (for gen_random_uuid if you later need it)
-- ---------------------------------------------------------------------------
-- create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1) ENUM types (safe)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'historical_layer_type') THEN
    CREATE TYPE public.historical_layer_type AS ENUM ('wms', 'raster', 'vector', 'tile');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'historical_admin_level') THEN
    CREATE TYPE public.historical_admin_level AS ENUM (
      'liwa','qada','muhafaza','nahiya','city','village','hamlet','quarter','camp'
    );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2) historical_periods (ensure required columns exist for app)
--    App expects: id (int), title_ar, title_en, start_year, end_year, is_default, order_index
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.historical_periods (
  id          SERIAL PRIMARY KEY,
  title_ar    TEXT NOT NULL,
  title_en    TEXT NULL,
  start_year  INTEGER NULL,
  end_year    INTEGER NULL,
  is_default  BOOLEAN NOT NULL DEFAULT FALSE,
  order_index INTEGER NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Backward-compat (if you had "name" column from older schema)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='historical_periods' AND column_name='name'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='historical_periods' AND column_name='title_ar'
  ) THEN
    ALTER TABLE public.historical_periods RENAME COLUMN name TO title_ar;
  END IF;
END $$;

-- Add missing columns safely (in case table existed already)
ALTER TABLE public.historical_periods
  ADD COLUMN IF NOT EXISTS title_ar TEXT,
  ADD COLUMN IF NOT EXISTS title_en TEXT NULL,
  ADD COLUMN IF NOT EXISTS start_year INTEGER NULL,
  ADD COLUMN IF NOT EXISTS end_year INTEGER NULL,
  ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS order_index INTEGER NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Ensure NOT NULL on title_ar only when safe
-- (skip enforcing if you might have null legacy rows)

-- updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_historical_periods_updated_at ON public.historical_periods;
CREATE TRIGGER trg_historical_periods_updated_at
BEFORE UPDATE ON public.historical_periods
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_historical_periods_order ON public.historical_periods(order_index);

-- ---------------------------------------------------------------------------
-- 3) historical_layers (used by GisScreen + HistoricalLayersPanel)
--    App expects: id, period_id, name_ar, name_en, type, url, z_index, is_active, metadata
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.historical_layers (
  id         SERIAL PRIMARY KEY,
  period_id  INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  name_ar    TEXT NOT NULL,
  name_en    TEXT NULL,
  type       public.historical_layer_type NOT NULL DEFAULT 'wms',
  url        TEXT NOT NULL,
  z_index    INTEGER NOT NULL DEFAULT 0,
  is_active  BOOLEAN NOT NULL DEFAULT TRUE,
  metadata   JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_historical_layers_updated_at ON public.historical_layers;
CREATE TRIGGER trg_historical_layers_updated_at
BEFORE UPDATE ON public.historical_layers
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_historical_layers_period ON public.historical_layers(period_id);
CREATE INDEX IF NOT EXISTS idx_historical_layers_active ON public.historical_layers(is_active);
CREATE INDEX IF NOT EXISTS idx_historical_layers_z ON public.historical_layers(z_index);

-- ---------------------------------------------------------------------------
-- 4) historical_map_snapshots (optional - repo expects this table)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.historical_map_snapshots (
  id          SERIAL PRIMARY KEY,
  period_id   INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  title_ar    TEXT NOT NULL,
  title_en    TEXT NULL,
  image_url   TEXT NOT NULL,
  description TEXT NULL,
  metadata    JSONB NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_historical_map_snapshots_updated_at ON public.historical_map_snapshots;
CREATE TRIGGER trg_historical_map_snapshots_updated_at
BEFORE UPDATE ON public.historical_map_snapshots
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_snapshots_period ON public.historical_map_snapshots(period_id);

-- ---------------------------------------------------------------------------
-- 5) waqf_lands (CRUD)
--    App expects: id int, pwf_code, name_ar, name_en, governorate, city,
--                 area_dunum, classification, status, lat, lng, notes, metadata, created_at, updated_at
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.waqf_lands (
  id            SERIAL PRIMARY KEY,
  pwf_code      TEXT NOT NULL,
  name_ar       TEXT NOT NULL,
  name_en       TEXT NULL,
  governorate   TEXT NULL,
  city          TEXT NULL,
  area_dunum    NUMERIC NULL,
  classification TEXT NOT NULL DEFAULT 'other',
  status        TEXT NOT NULL DEFAULT 'active',
  lat           DOUBLE PRECISION NULL,
  lng           DOUBLE PRECISION NULL,
  notes         TEXT NULL,
  metadata      JSONB NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_waqf_lands_pwf_code ON public.waqf_lands(pwf_code);
CREATE INDEX IF NOT EXISTS idx_waqf_lands_name_ar ON public.waqf_lands(name_ar);
CREATE INDEX IF NOT EXISTS idx_waqf_lands_city ON public.waqf_lands(city);

DROP TRIGGER IF EXISTS trg_waqf_lands_updated_at ON public.waqf_lands;
CREATE TRIGGER trg_waqf_lands_updated_at
BEFORE UPDATE ON public.waqf_lands
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 6) historical_admin_units (CRUD)
--    Designed to support your existing Flutter fields + future metadata.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.historical_admin_units (
  id          SERIAL PRIMARY KEY,
  period_id   INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  level       public.historical_admin_level NOT NULL,
  code        TEXT NULL,
  name_ar     TEXT NOT NULL,
  name_en     TEXT NULL,
  parent_id   INTEGER NULL REFERENCES public.historical_admin_units(id) ON UPDATE CASCADE ON DELETE SET NULL,
  area_km2    NUMERIC NULL,
  population  INTEGER NULL,
  alt_names   JSONB NULL,
  metadata    JSONB NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_historical_admin_units_updated_at ON public.historical_admin_units;
CREATE TRIGGER trg_historical_admin_units_updated_at
BEFORE UPDATE ON public.historical_admin_units
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_hau_period ON public.historical_admin_units(period_id);
CREATE INDEX IF NOT EXISTS idx_hau_level ON public.historical_admin_units(level);
CREATE INDEX IF NOT EXISTS idx_hau_parent ON public.historical_admin_units(parent_id);
CREATE INDEX IF NOT EXISTS idx_hau_name_ar ON public.historical_admin_units(name_ar);

-- Optional uniqueness to prevent duplicates inside same period+level
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_hau_period_level_name
--   ON public.historical_admin_units(period_id, level, name_ar);

-- ---------------------------------------------------------------------------
-- 7) land_admin_history (link land -> historical admin unit by period)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.land_admin_history (
  id            SERIAL PRIMARY KEY,
  land_id       INTEGER NOT NULL REFERENCES public.waqf_lands(id) ON UPDATE CASCADE ON DELETE CASCADE,
  period_id     INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  admin_unit_id INTEGER NOT NULL REFERENCES public.historical_admin_units(id) ON UPDATE CASCADE ON DELETE CASCADE,
  notes         TEXT NULL,
  metadata      JSONB NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lah_land ON public.land_admin_history(land_id);
CREATE INDEX IF NOT EXISTS idx_lah_period ON public.land_admin_history(period_id);
CREATE INDEX IF NOT EXISTS idx_lah_unit ON public.land_admin_history(admin_unit_id);

-- Prevent accidental duplicates (optional)
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_lah_unique
--   ON public.land_admin_history(land_id, period_id, admin_unit_id);

COMMIT;
