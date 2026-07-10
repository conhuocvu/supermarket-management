-- 1. Create or replace trigger function to sync auth.users to public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  default_role_num INTEGER;
BEGIN
  -- Default to role_number 3 (Stock Controller) which is the lowest privilege role in the schema
  default_role_num := 3;

  INSERT INTO public.profiles (user_id, role_number, full_name, phone, status, created_at)
  VALUES (
    new.id,
    default_role_num,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    'ACTIVE'::public.user_status,
    now()
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Failed to create user profile: %', SQLERRM;
END;
$$;

-- Apply trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 2. Security helper functions to check roles (security definer to bypass RLS recursion)
CREATE OR REPLACE FUNCTION public.is_admin(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE user_id = user_uuid AND role_number = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_user_role(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
STABLE
AS $$
DECLARE
  role_num INTEGER;
BEGIN
  SELECT role_number INTO role_num FROM public.profiles WHERE user_id = user_uuid;
  RETURN role_num;
END;
$$;

-- 3. Profiles RLS Policies (Enable RLS if not already enabled)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow users to read own profile" ON public.profiles;
CREATE POLICY "Allow users to read own profile" ON public.profiles
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Allow admins to read all profiles" ON public.profiles;
CREATE POLICY "Allow admins to read all profiles" ON public.profiles
  FOR SELECT TO authenticated USING (public.is_admin(auth.uid()));

DROP POLICY IF EXISTS "Allow users to update own profile fields" ON public.profiles;
CREATE POLICY "Allow users to update own profile fields" ON public.profiles
  FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id AND role_number = public.get_user_role(auth.uid()));

DROP POLICY IF EXISTS "Allow admins to update all profiles" ON public.profiles;
CREATE POLICY "Allow admins to update all profiles" ON public.profiles
  FOR UPDATE TO authenticated USING (public.is_admin(auth.uid()));

-- 4. Roles RLS Policies (Enable RLS if not already enabled)
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow select for authenticated users" ON public.roles;
CREATE POLICY "Allow select for authenticated users" ON public.roles
  FOR SELECT TO authenticated USING (true);
