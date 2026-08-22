-- 러닝 기록 보완: 평균 심박수 / 총 칼로리 소모량 / 메인 사진.
-- (총 이동거리·러닝 시간은 이미 distance_meters·duration_seconds로 존재하고,
--  평균 페이스는 그 둘에서 계산하므로 별도 컬럼을 두지 않는다.)
ALTER TABLE public.running_records
    ADD COLUMN IF NOT EXISTS avg_heart_rate INTEGER,
    ADD COLUMN IF NOT EXISTS calories_burned DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS photo_path TEXT;

-- 메인 사진 저장용 버킷 (travel-photos와 동일 패턴)
INSERT INTO storage.buckets (id, name, public)
VALUES ('running-photos', 'running-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "running_photos_read" ON storage.objects;
DROP POLICY IF EXISTS "running_photos_write" ON storage.objects;
DROP POLICY IF EXISTS "running_photos_delete" ON storage.objects;

CREATE POLICY "running_photos_read" ON storage.objects
    FOR SELECT TO anon, authenticated USING (bucket_id = 'running-photos');
CREATE POLICY "running_photos_write" ON storage.objects
    FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'running-photos');
CREATE POLICY "running_photos_delete" ON storage.objects
    FOR DELETE TO anon, authenticated USING (bucket_id = 'running-photos');
