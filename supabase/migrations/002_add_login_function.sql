-- 비밀번호 해시(crypt) 비교를 위한 확장
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- users 테이블 직접 접근 차단 (password_hash 노출 방지)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- username + password 검증 전용 함수
-- SECURITY DEFINER로 실행되어 RLS를 우회해 조회하되, password_hash는 반환하지 않음
CREATE OR REPLACE FUNCTION public.login(p_username VARCHAR, p_password TEXT)
RETURNS TABLE (
    id UUID,
    username VARCHAR,
    name VARCHAR,
    phone_number VARCHAR,
    role VARCHAR,
    avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.name, u.phone_number, u.role, u.avatar_url
    FROM public.users u
    WHERE u.username = p_username
      AND u.password_hash = crypt(p_password, u.password_hash);
END;
$$;

-- anon(로그인 전 클라이언트)도 이 함수는 호출 가능해야 함
GRANT EXECUTE ON FUNCTION public.login(VARCHAR, TEXT) TO anon, authenticated;
