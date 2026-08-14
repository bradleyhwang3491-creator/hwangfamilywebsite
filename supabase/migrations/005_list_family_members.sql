CREATE OR REPLACE FUNCTION public.list_family_members()
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    avatar_url TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT u.id, u.name, u.avatar_url
    FROM public.users u
    ORDER BY u.created_at;
$$;

GRANT EXECUTE ON FUNCTION public.list_family_members() TO anon, authenticated;
