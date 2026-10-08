-- 活動雷達：公開活動表（任何人可讀取、可新增；不可修改、刪除）
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 80),
  event_date date not null,
  start_time text not null default '',
  end_time text not null default '',
  place text not null default '' check (char_length(place) <= 120),
  area text not null default '' check (char_length(area) <= 40),
  district text not null default '' check (char_length(district) <= 20),
  type text not null default '市集' check (char_length(type) <= 20),
  source text not null default '貼文' check (char_length(source) <= 20),
  created_at timestamptz not null default now()
);
alter table public.events enable row level security;

drop policy if exists "任何人可讀取活動" on public.events;
create policy "任何人可讀取活動" on public.events for select to anon, authenticated using (true);
drop policy if exists "任何人可新增活動" on public.events;
create policy "任何人可新增活動" on public.events for insert to anon, authenticated with check (true);

grant select, insert on public.events to anon, authenticated;

insert into public.events (title,event_date,start_time,end_time,place,area,district,type,source)
select title,event_date::date,start_time,end_time,place,area,district,type,source from (values
 ('秋季手作市集','2026-10-17','11:00','19:00','華山1914文創園區 中4館','華山文創','中正區','市集','Instagram'),
 ('光影裝置展：城市夜行','2026-10-10','10:00','21:00','松山文創園區 2號倉庫','松菸文創','信義區','展覽','網站'),
 ('獨立樂團週末小夜場','2026-10-24','19:30','22:00','大安區忠孝敦化 Live House','東區','大安區','音樂表演','Facebook'),
 ('迪化街年貨前哨 · 老店試吃','2026-11-07','10:00','17:00','迪化街一段 霞海城隍廟前','迪化街','大同區','美食','Threads'),
 ('親子環保工作坊','2026-10-18','14:00','16:30','公館商圈 水源市場二樓','公館商圈','中正區','親子','Facebook'),
 ('信義商圈跨年前夕路跑','2026-11-15','06:30','10:00','台北市政府前廣場','信義商圈','信義區','運動','網站'),
 ('西門町街頭藝人嘉年華','2026-10-31','15:00','21:00','西門紅樓前廣場','西門町','萬華區','音樂表演','Instagram'),
 ('精品咖啡嘉年華','2026-11-21','10:00','18:00','新板特區 新北大都會公園','板橋新板特區','板橋區','美食','Instagram'),
 ('城市攝影講座：用手機拍夜市','2026-10-14','19:00','21:00','士林夜市 文化會館','士林夜市','士林區','講座工作坊','網站'),
 ('雙連朝市 × 在地選物小市集','2026-12-05','09:00','15:00','中山區雙連站旁 朝市','中山雙連','中山區','市集','Threads'),
 ('東區聖誕燈飾點燈儀式','2026-12-12','18:00','21:30','忠孝敦化商圈','東區','大安區','展覽','Facebook'),
 ('迪化街手沖茶藝體驗工作坊','2026-12-19','13:30','16:00','迪化街 老屋茶室','迪化街','大同區','講座工作坊','網站')
) as v(title,event_date,start_time,end_time,place,area,district,type,source)
where not exists (select 1 from public.events);
