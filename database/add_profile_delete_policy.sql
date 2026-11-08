-- Kullanıcıların kendi profillerini silebilmesi için RLS politikası
DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;

CREATE POLICY "Users can delete own profile" ON public.user_profiles
  FOR DELETE
  USING (auth.uid() = id);
