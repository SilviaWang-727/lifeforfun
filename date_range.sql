-- 活動雷達：events 新增欄位
alter table public.events add column if not exists end_date date;
alter table public.events add column if not exists source_url text check (source_url is null or char_length(source_url) <= 500);
notify pgrst, 'reload schema';
