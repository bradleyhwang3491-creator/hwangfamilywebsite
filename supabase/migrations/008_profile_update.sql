-- 마이페이지 프로필 수정용 RPC. login()/list_family_members()(002/005)와 동일하게
-- users 테이블은 RLS로 막혀있고, 이 SECURITY DEFINER 함수만 뚫어서 수정 가능하게 함.
CREATE OR REPLACE FUNCTION public.update_profile(
    p_user_id UUID,
    p_name VARCHAR,
    p_phone_number VARCHAR,
    p_avatar_url TEXT
)
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
    UPDATE public.users u
    SET name = p_name,
        phone_number = p_phone_number,
        avatar_url = p_avatar_url,
        updated_at = NOW()
    WHERE u.id = p_user_id;

    RETURN QUERY
    SELECT u.id, u.username, u.name, u.phone_number, u.role, u.avatar_url
    FROM public.users u
    WHERE u.id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_profile(UUID, VARCHAR, VARCHAR, TEXT) TO anon, authenticated;

-- Storage bucket for profile avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "avatars_read" ON storage.objects
    FOR SELECT TO anon, authenticated USING (bucket_id = 'avatars');

CREATE POLICY "avatars_write" ON storage.objects
    FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "avatars_delete" ON storage.objects
    FOR DELETE TO anon, authenticated USING (bucket_id = 'avatars');
