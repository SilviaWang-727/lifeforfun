revoke update, delete on public.events from anon, authenticated;
-- 保留給 anon 與 authenticated 的權限只剩讀取與新增
notify pgrst, 'reload schema';
