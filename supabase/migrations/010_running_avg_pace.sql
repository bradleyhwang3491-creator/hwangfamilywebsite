-- 평균 페이스를 사용자가 직접 수정할 수 있도록 별도 컬럼으로 저장한다.
-- (거리/시간에서 계산만 하던 값이었으나, 6개 항목 모두 수정 가능해야 함)
ALTER TABLE public.running_records
    ADD COLUMN IF NOT EXISTS avg_pace_seconds INTEGER;

-- 기존 기록은 거리/시간으로 계산한 값을 채워둔다.
UPDATE public.running_records
SET avg_pace_seconds = ROUND(duration_seconds / (distance_meters / 1000.0))
WHERE avg_pace_seconds IS NULL
  AND distance_meters > 0
  AND duration_seconds > 0;
