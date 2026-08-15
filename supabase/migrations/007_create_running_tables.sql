-- 러닝 기록: 앱에서 직접 GPS로 트래킹해서 저장 (Health Connect 연동 아님).
CREATE TABLE IF NOT EXISTS public.running_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id),
    title VARCHAR(100) NOT NULL,
    run_date DATE NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    duration_seconds INTEGER NOT NULL,
    distance_meters DOUBLE PRECISION NOT NULL,
    avg_speed_kmh DOUBLE PRECISION,
    max_heart_rate INTEGER,
    route JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (end_time >= start_time)
);

-- 가족 공유 anon key 구조 (travel_records와 동일 패턴)
ALTER TABLE public.running_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "running_records_all" ON public.running_records
    FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
