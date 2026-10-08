-- 活動雷達：events 新增結束日期欄位（區間活動用，單日活動留空）
alter table public.events add column if not exists end_date date;
