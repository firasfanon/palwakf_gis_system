-- v5: Historical periods support for content (news + announcements)
-- Assumptions:
-- 1) public.historical_periods currently has: id serial, name text, start_year int, end_year int, order_index int
-- 2) mustakshif_news / mustakshif_announcements use uuid primary key for id
-- 3) We want historical_period_id INTEGER NULL in both content tables, FK -> historical_periods(id)

BEGIN;

-- 0) Upgrade historical_periods schema to match app model (title_ar/title_en/is_default)
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

ALTER TABLE public.historical_periods
  ADD COLUMN IF NOT EXISTS title_en text NULL;

ALTER TABLE public.historical_periods
  ADD COLUMN IF NOT EXISTS is_default boolean NOT NULL DEFAULT false;

-- Ensure order_index exists (already in your schema, but keep safe)
ALTER TABLE public.historical_periods
  ADD COLUMN IF NOT EXISTS order_index integer NULL;

-- 1) MUSTAKSHIF NEWS: fix historical_period_id type and FK
ALTER TABLE public.mustakshif_news
  DROP CONSTRAINT IF EXISTS mustakshif_news_historical_period_fk;

ALTER TABLE public.mustakshif_news
  DROP COLUMN IF EXISTS historical_period_id;

ALTER TABLE public.mustakshif_news
  ADD COLUMN historical_period_id integer NULL;

ALTER TABLE public.mustakshif_news
  ADD CONSTRAINT mustakshif_news_historical_period_fk
  FOREIGN KEY (historical_period_id) REFERENCES public.historical_periods(id)
  ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_mustakshif_news_historical_period_id
  ON public.mustakshif_news (historical_period_id);

-- 2) MUSTAKSHIF ANNOUNCEMENTS: fix historical_period_id type and FK
ALTER TABLE public.mustakshif_announcements
  DROP CONSTRAINT IF EXISTS mustakshif_announcements_historical_period_fk;

ALTER TABLE public.mustakshif_announcements
  DROP COLUMN IF EXISTS historical_period_id;

ALTER TABLE public.mustakshif_announcements
  ADD COLUMN historical_period_id integer NULL;

ALTER TABLE public.mustakshif_announcements
  ADD CONSTRAINT mustakshif_announcements_historical_period_fk
  FOREIGN KEY (historical_period_id) REFERENCES public.historical_periods(id)
  ON UPDATE CASCADE ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_mustakshif_announcements_historical_period_id
  ON public.mustakshif_announcements (historical_period_id);

-- 3) Seed periods (ONLY if table is empty)
INSERT INTO public.historical_periods (title_ar, title_en, start_year, end_year, order_index, is_default)
SELECT * FROM (VALUES
  ('العهد العثماني', 'Ottoman period', 1516, 1917, 10, true),
  ('الانتداب البريطاني', 'British Mandate', 1917, 1948, 20, false),
  ('العهد الأردني / المصري', 'Jordanian/Egyptian administration', 1948, 1967, 30, false),
  ('فترة ما بعد 1967', 'Post-1967', 1967, NULL, 40, false)
) AS v(title_ar, title_en, start_year, end_year, order_index, is_default)
WHERE NOT EXISTS (SELECT 1 FROM public.historical_periods);

COMMIT;
