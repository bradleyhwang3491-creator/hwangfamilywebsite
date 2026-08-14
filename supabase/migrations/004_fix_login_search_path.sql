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
SET search_path = public, extensions
AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.username, u.name, u.phone_number, u.role, u.avatar_url
    FROM public.users u
    WHERE u.username = p_username
      AND u.password_hash = crypt(p_password, u.password_hash::text);
END;
$$;
