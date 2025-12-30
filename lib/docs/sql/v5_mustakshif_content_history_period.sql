-- v5: ربط الأخبار/الإعلانات بالفترات التاريخية (اختياري) + تهيئة جدول الفترات
--
-- هذا السكربت "آمن" لمشروعك الحالي لأن:
-- 1) يعالج اختلاف نوع historical_period_id (uuid vs integer) عبر إعادة إنشائه كـ integer.
-- 2) يحدّث جدول historical_periods ليتوافق مع موديلات Flutter (title_ar/title_en/is_default).
-- 3) يزرع بيانات فترات ابتدائية فقط إذا كان جدول historical_periods فارغًا.

BEGIN;

-- ---------------------------------------------------------------------------
-- A) historical_periods: توافق مع الموديل (title_ar/title_en/is_default)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  -- إذا كان لديك عمود name (schema القديم)، قم بإعادة تسميته إلى title_ar.
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'historical_periods'
      AND column_name = 'name'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'historical_periods'
      AND column_name = 'title_ar'
  ) THEN
    EXECUTE 'ALTER TABLE public.historical_periods RENAME COLUMN name TO title_ar';
  END IF;

  -- أنشئ title_ar إن لم يوجد (احتياط)
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'historical_periods'
      AND column_name = 'title_ar'
  ) THEN
    EXECUTE 'ALTER TABLE public.historical_periods ADD COLUMN title_ar text';
  END IF;

  -- title_en / is_default
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'historical_periods'
      AND column_name = 'title_en'
  ) THEN
    EXECUTE 'ALTER TABLE public.historical_periods ADD COLUMN title_en text NULL';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'historical_periods'
      AND column_name = 'is_default'
  ) THEN
    EXECUTE 'ALTER TABLE public.historical_periods ADD COLUMN is_default boolean NOT NULL DEFAULT false';
  END IF;

  -- اجعل title_ar NOT NULL (إذا كان الجدول فارغًا أو إن كانت كل القيم موجودة)
  -- لن نقوم بفرض NOT NULL إن كان لديك بيانات قديمة قد تحتوي NULL.
END $$;

-- ---------------------------------------------------------------------------
-- B) mustakshif_news / mustakshif_announcements: historical_period_id = integer
-- ---------------------------------------------------------------------------

-- NEWS
ALTER TABLE public.mustakshif_news
  DROP CONSTRAINT IF EXISTS mustakshif_news_historical_period_fk;

DO $$
DECLARE
  col_udt text;
BEGIN
  SELECT udt_name INTO col_udt
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mustakshif_news'
    AND column_name = 'historical_period_id';

  -- إن كان موجودًا ولكن ليس integer، احذفه.
  IF col_udt IS NOT NULL AND col_udt <> 'int4' THEN
    EXECUTE 'ALTER TABLE public.mustakshif_news DROP COLUMN historical_period_id';
  END IF;
END $$;

ALTER TABLE public.mustakshif_news
  ADD COLUMN IF NOT EXISTS historical_period_id integer NULL;

-- ANNOUNCEMENTS
ALTER TABLE public.mustakshif_announcements
  DROP CONSTRAINT IF EXISTS mustakshif_announcements_historical_period_fk;

DO $$
DECLARE
  col_udt text;
BEGIN
  SELECT udt_name INTO col_udt
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mustakshif_announcements'
    AND column_name = 'historical_period_id';

  IF col_udt IS NOT NULL AND col_udt <> 'int4' THEN
    EXECUTE 'ALTER TABLE public.mustakshif_announcements DROP COLUMN historical_period_id';
  END IF;
END $$;

ALTER TABLE public.mustakshif_announcements
  ADD COLUMN IF NOT EXISTS historical_period_id integer NULL;

-- FK constraints (إذا كان historical_periods موجود)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'historical_periods'
  ) THEN
    BEGIN
      ALTER TABLE public.mustakshif_news
        ADD CONSTRAINT mustakshif_news_historical_period_fk
        FOREIGN KEY (historical_period_id) REFERENCES public.historical_periods(id)
        ON UPDATE CASCADE ON DELETE SET NULL;
    EXCEPTION WHEN duplicate_object THEN
      -- ignore
    END;

    BEGIN
      ALTER TABLE public.mustakshif_announcements
        ADD CONSTRAINT mustakshif_announcements_historical_period_fk
        FOREIGN KEY (historical_period_id) REFERENCES public.historical_periods(id)
        ON UPDATE CASCADE ON DELETE SET NULL;
    EXCEPTION WHEN duplicate_object THEN
      -- ignore
    END;
  END IF;
END$$;

-- Indexes للأداء
CREATE INDEX IF NOT EXISTS idx_mustakshif_news_historical_period_id
  ON public.mustakshif_news (historical_period_id);

CREATE INDEX IF NOT EXISTS idx_mustakshif_announcements_historical_period_id
  ON public.mustakshif_announcements (historical_period_id);

-- ---------------------------------------------------------------------------
-- C) Seed: إدراج فترات ابتدائية (فقط إذا كان جدول historical_periods فارغًا)
-- ---------------------------------------------------------------------------

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM public.historical_periods) = 0 THEN
    INSERT INTO public.historical_periods (title_ar, title_en, start_year, end_year, order_index, is_default)
    VALUES
      ('العهد العثماني', 'Ottoman period', 1516, 1917, 10, false),
      ('الانتداب البريطاني', 'British Mandate', 1917, 1948, 20, false),
      ('الإدارة الأردنية (الضفة الغربية)', 'Jordanian administration (West Bank)', 1948, 1967, 30, false),
      ('الإدارة المصرية (قطاع غزة)', 'Egyptian administration (Gaza)', 1948, 1967, 40, false),
      ('مرحلة ما بعد 1967', 'Post-1967', 1967, 1994, 50, false),
      ('السلطة الوطنية الفلسطينية', 'Palestinian Authority', 1994, NULL, 60, true);
  END IF;
END$$;

COMMIT;

-- Done.
