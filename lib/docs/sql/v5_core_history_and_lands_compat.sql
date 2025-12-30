-- v5_core_history_and_lands_compat.sql
-- Compatibility migration for existing schema (based on pasted.txt):
-- - historical_periods currently: id, name, start_year, end_year, order_index
-- - historical_admin_units currently: id, name, period_id
-- - waqf_lands currently: id, name, ... , pw_id, pwf_code (may or may not exist depending on env)
--
-- Goal: make schema compatible with v5 Flutter models WITHOUT dropping existing data.

BEGIN;

-- 0) Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Enums (safe)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'historical_layer_type') THEN
    CREATE TYPE public.historical_layer_type AS ENUM ('wms', 'raster', 'vector', 'tile');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'historical_admin_level') THEN
    CREATE TYPE public.historical_admin_level AS ENUM ('liwa', 'qada', 'muhafaza', 'city', 'village', 'camp', 'other');
  END IF;
END $$;

-- 2) historical_periods: upgrade in-place (keep existing name column)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='public' AND table_name='historical_periods'
  ) THEN
    -- Add new columns if missing
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_periods' AND column_name='title_ar'
    ) THEN
      ALTER TABLE public.historical_periods ADD COLUMN title_ar TEXT;
      -- Backfill from name if present
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='historical_periods' AND column_name='name'
      ) THEN
        UPDATE public.historical_periods SET title_ar = COALESCE(title_ar, name);
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_periods' AND column_name='title_en'
    ) THEN
      ALTER TABLE public.historical_periods ADD COLUMN title_en TEXT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_periods' AND column_name='is_default'
    ) THEN
      ALTER TABLE public.historical_periods ADD COLUMN is_default BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_periods' AND column_name='created_at'
    ) THEN
      ALTER TABLE public.historical_periods ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_periods' AND column_name='updated_at'
    ) THEN
      ALTER TABLE public.historical_periods ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;

    -- Ensure title_ar is filled
    UPDATE public.historical_periods
    SET title_ar = COALESCE(title_ar, 'غير محدد')
    WHERE title_ar IS NULL;

    -- Optional: index for ordering
    CREATE INDEX IF NOT EXISTS idx_historical_periods_order ON public.historical_periods (order_index);
  END IF;
END $$;

-- 3) historical_layers (create if missing)
CREATE TABLE IF NOT EXISTS public.historical_layers (
  id              SERIAL PRIMARY KEY,
  period_id        INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  type            public.historical_layer_type NOT NULL DEFAULT 'wms',
  name_ar         TEXT NOT NULL,
  name_en         TEXT NULL,
  source_url      TEXT NOT NULL,
  wms_layer_name  TEXT NULL,
  opacity         INTEGER NOT NULL DEFAULT 60,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  default_visible BOOLEAN NOT NULL DEFAULT TRUE,
  z_index         INTEGER NOT NULL DEFAULT 0,
  metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_historical_layers_period ON public.historical_layers(period_id);
CREATE INDEX IF NOT EXISTS idx_historical_layers_active ON public.historical_layers(is_active);

-- 4) historical_admin_units: upgrade in-place if table exists; otherwise create
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='public' AND table_name='historical_admin_units'
  ) THEN
    -- Add columns expected by v5
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='level'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN level public.historical_admin_level;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='code'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN code TEXT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='name_ar'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN name_ar TEXT;
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='name'
      ) THEN
        UPDATE public.historical_admin_units SET name_ar = COALESCE(name_ar, name);
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='name_en'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN name_en TEXT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='parent_id'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN parent_id INTEGER;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='area_km2'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN area_km2 NUMERIC;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='population'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN population INTEGER;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='alt_names'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN alt_names JSONB;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='metadata'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN metadata JSONB;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='created_at'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='historical_admin_units' AND column_name='updated_at'
    ) THEN
      ALTER TABLE public.historical_admin_units ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;

    -- FK for parent_id if missing
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conname = 'historical_admin_units_parent_id_fkey'
    ) THEN
      ALTER TABLE public.historical_admin_units
        ADD CONSTRAINT historical_admin_units_parent_id_fkey
        FOREIGN KEY (parent_id) REFERENCES public.historical_admin_units(id)
        ON UPDATE CASCADE ON DELETE SET NULL;
    END IF;

    -- Ensure period_id FK exists
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conname = 'historical_admin_units_period_id_fkey'
    ) THEN
      ALTER TABLE public.historical_admin_units
        ADD CONSTRAINT historical_admin_units_period_id_fkey
        FOREIGN KEY (period_id) REFERENCES public.historical_periods(id)
        ON UPDATE CASCADE ON DELETE CASCADE;
    END IF;

    -- Basic indexes used by list screens
    CREATE INDEX IF NOT EXISTS idx_hau_period ON public.historical_admin_units(period_id);
    CREATE INDEX IF NOT EXISTS idx_hau_parent ON public.historical_admin_units(parent_id);
    CREATE INDEX IF NOT EXISTS idx_hau_name_ar ON public.historical_admin_units(name_ar);
  ELSE
    -- Create full table if it doesn't exist
    CREATE TABLE public.historical_admin_units (
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

    CREATE INDEX IF NOT EXISTS idx_hau_period ON public.historical_admin_units(period_id);
    CREATE INDEX IF NOT EXISTS idx_hau_parent ON public.historical_admin_units(parent_id);
    CREATE INDEX IF NOT EXISTS idx_hau_name_ar ON public.historical_admin_units(name_ar);
  END IF;
END $$;

-- 5) land_admin_history (create if missing)
CREATE TABLE IF NOT EXISTS public.land_admin_history (
  id           BIGSERIAL PRIMARY KEY,
  land_id      INTEGER NOT NULL REFERENCES public.waqf_lands(id) ON UPDATE CASCADE ON DELETE CASCADE,
  period_id    INTEGER NOT NULL REFERENCES public.historical_periods(id) ON UPDATE CASCADE ON DELETE CASCADE,
  admin_unit_id INTEGER NOT NULL REFERENCES public.historical_admin_units(id) ON UPDATE CASCADE ON DELETE CASCADE,
  notes        TEXT NULL,
  metadata     JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(land_id, period_id, admin_unit_id)
);

CREATE INDEX IF NOT EXISTS idx_land_admin_history_land ON public.land_admin_history(land_id);
CREATE INDEX IF NOT EXISTS idx_land_admin_history_period ON public.land_admin_history(period_id);

-- 6) waqf_lands: ensure columns used by Flutter v5 exist (without dropping existing columns)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='public' AND table_name='waqf_lands'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='waqf_lands' AND column_name='pwf_code'
    ) THEN
      ALTER TABLE public.waqf_lands ADD COLUMN pwf_code TEXT;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='waqf_lands' AND column_name='name_ar'
    ) THEN
      ALTER TABLE public.waqf_lands ADD COLUMN name_ar TEXT;
      IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='waqf_lands' AND column_name='name'
      ) THEN
        UPDATE public.waqf_lands SET name_ar = COALESCE(name_ar, name);
      END IF;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='waqf_lands' AND column_name='name_en'
    ) THEN
      ALTER TABLE public.waqf_lands ADD COLUMN name_en TEXT;
    END IF;

    -- Backfill pwf_code from pw_id if available
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='waqf_lands' AND column_name='pw_id'
    ) THEN
      UPDATE public.waqf_lands SET pwf_code = COALESCE(pwf_code, pw_id) WHERE pwf_code IS NULL;
    END IF;

    -- Ensure non-null for UI fields (can tighten later)
    UPDATE public.waqf_lands SET name_ar = COALESCE(name_ar, 'غير محدد') WHERE name_ar IS NULL;

    -- Helpful indexes
    CREATE INDEX IF NOT EXISTS idx_waqf_lands_pwf_code ON public.waqf_lands(pwf_code);
    CREATE INDEX IF NOT EXISTS idx_waqf_lands_name_ar ON public.waqf_lands(name_ar);
  END IF;
END $$;

COMMIT;
