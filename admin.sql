-- 活動雷達：只有管理員 email 能修改、刪除 events
revoke update, delete on public.events from anon;
grant update, delete on public.events to authenticated;

drop policy if exists "管理員可修改活動" on public.events;
create policy "管理員可修改活動" on public.events for update to authenticated
  using ((auth.jwt() ->> 'email') = 'silviawang@nine-yi.com')
  with check ((auth.jwt() ->> 'email') = 'silviawang@nine-yi.com');

drop policy if exists "管理員可刪除活動" on public.events;
create policy "管理員可刪除活動" on public.events for delete to authenticated
  using ((auth.jwt() ->> 'email') = 'silviawang@nine-yi.com');
