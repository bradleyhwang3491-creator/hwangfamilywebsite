CREATE TABLE IF NOT EXISTS public.travel_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id),
    title VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    country VARCHAR(100),
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    is_domestic BOOLEAN,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_date >= start_date)
);

CREATE TABLE IF NOT EXISTS public.travel_record_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    travel_record_id UUID NOT NULL REFERENCES public.travel_records(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    sort_order SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- No password-equivalent secrets on these tables, so keep access simple:
-- the whole family shares the anon key (custom RPC login, not Supabase Auth),
-- so allow that key to read/write directly instead of RPC-wrapping everything.
ALTER TABLE public.travel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.travel_record_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "travel_records_all" ON public.travel_records
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY "travel_record_photos_all" ON public.travel_record_photos
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- Storage bucket for travel photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('travel-photos', 'travel-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "travel_photos_read" ON storage.objects
    FOR SELECT TO anon, authenticated USING (bucket_id = 'travel-photos');

CREATE POLICY "travel_photos_write" ON storage.objects
    FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'travel-photos');

CREATE POLICY "travel_photos_delete" ON storage.objects
    FOR DELETE TO anon, authenticated USING (bucket_id = 'travel-photos');
