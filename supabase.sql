-- 活動雷達：Supabase 資料庫設定
-- 貼到 Supabase 後台 → SQL Editor → New query → Run

-- 1. 每位使用者一列，存整份清單（只有本人能讀寫）
create table if not exists public.user_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.user_state enable row level security;

drop policy if exists "本人讀取" on public.user_state;
create policy "本人讀取" on public.user_state for select to authenticated using (user_id = auth.uid());
drop policy if exists "本人新增" on public.user_state;
create policy "本人新增" on public.user_state for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "本人修改" on public.user_state;
create policy "本人修改" on public.user_state for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 2. 分享清單：登入者可建立，別人只能用分享代碼讀取單一份
create table if not exists public.shares (
  code text primary key,
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  events jsonb not null,
  created_at timestamptz not null default now()
);
alter table public.shares enable row level security;

drop policy if exists "登入者建立分享" on public.shares;
create policy "登入者建立分享" on public.shares for insert to authenticated with check (owner = auth.uid());
drop policy if exists "本人查看自己的分享" on public.shares;
create policy "本人查看自己的分享" on public.shares for select to authenticated using (owner = auth.uid());
drop policy if exists "本人刪除自己的分享" on public.shares;
create policy "本人刪除自己的分享" on public.shares for delete to authenticated using (owner = auth.uid());

-- 沒有任何人能列出全部分享；只能憑代碼取單一份（含未登入的朋友）
create or replace function public.get_share(p_code text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object('name', name, 'events', events) from public.shares where code = p_code;
$$;
revoke all on function public.get_share(text) from public;
grant execute on function public.get_share(text) to anon, authenticated;
