-- U&M Designs — Export customer feedback
-- Run this once in Supabase → SQL Editor → New query → Run.
-- Safe to re-run: every statement is idempotent.

create extension if not exists pgcrypto;

-- ---------- tables ----------
create table if not exists customers (
  id          uuid primary key default gen_random_uuid(),
  company     text not null,
  country     text not null default '',
  created_at  timestamptz not null default now(),
  unique (company)
);

create table if not exists links (
  id           uuid primary key default gen_random_uuid(),
  code         text not null unique,
  customer_id  uuid not null references customers(id) on delete cascade,
  contact      text not null,
  email        text not null default '',
  depts        text[] not null check (array_length(depts,1) >= 1),   -- subset of {A,B,C,D}
  created_at   timestamptz not null default now(),
  opened_at    timestamptz,
  answered_at  timestamptz
);
create index if not exists links_customer_idx on links(customer_id);

create table if not exists responses (
  id            uuid primary key default gen_random_uuid(),
  link_id       uuid not null unique references links(id) on delete cascade,
  ratings       jsonb not null,            -- {"6":4,"7":"NA",...}  question number -> 1..5 or "NA"
  remarks       jsonb not null default '{}'::jsonb,
  open_answers  jsonb not null default '{}'::jsonb,
  submitted_at  timestamptz not null default now()
);

-- ---------- link codes: 7 chars, no look-alike letters ----------
create or replace function gen_link_code() returns text language plpgsql as $$
declare
  alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  out text; i int; tries int := 0;
begin
  loop
    out := '';
    for i in 1..7 loop
      out := out || substr(alphabet, 1 + floor(random()*length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from links where code = out);
    tries := tries + 1;
    if tries > 20 then raise exception 'could not generate unique code'; end if;
  end loop;
  return out;
end $$;

create or replace function links_set_code() returns trigger language plpgsql as $$
begin
  if new.code is null or new.code = '' then new.code := gen_link_code(); end if;
  return new;
end $$;
drop trigger if exists links_set_code_trg on links;
create trigger links_set_code_trg before insert on links for each row execute function links_set_code();

-- ---------- security ----------
alter table customers enable row level security;
alter table links     enable row level security;
alter table responses enable row level security;

-- Logged-in U&M users (created by you in Authentication → Users) can do everything.
drop policy if exists staff_all on customers;
create policy staff_all on customers for all to authenticated using (true) with check (true);
drop policy if exists staff_all on links;
create policy staff_all on links     for all to authenticated using (true) with check (true);
drop policy if exists staff_all on responses;
create policy staff_all on responses for all to authenticated using (true) with check (true);

-- The public form never touches tables directly. It only calls these two functions,
-- which run with elevated rights but expose exactly one link per code.

create or replace function get_link(p_code text)
returns table (company text, country text, contact text, depts text[], answered boolean)
language plpgsql security definer set search_path = public as $$
begin
  update links set opened_at = coalesce(opened_at, now()) where code = upper(trim(p_code));
  return query
    select c.company, c.country, l.contact, l.depts, (l.answered_at is not null)
    from links l join customers c on c.id = l.customer_id
    where l.code = upper(trim(p_code));
end $$;

create or replace function submit_response(p_code text, p_ratings jsonb, p_remarks jsonb, p_open jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare v_link links%rowtype; k text; v jsonb;
begin
  select * into v_link from links where code = upper(trim(p_code));
  if not found then raise exception 'invalid link'; end if;
  if v_link.answered_at is not null then raise exception 'already answered'; end if;
  if jsonb_typeof(p_ratings) <> 'object' then raise exception 'bad ratings'; end if;
  -- each rating must be 1..5 or "NA"
  for k, v in select * from jsonb_each(p_ratings) loop
    if not ((jsonb_typeof(v)='number' and (v::text)::numeric between 1 and 5) or v = '"NA"'::jsonb) then
      raise exception 'bad rating value for %', k;
    end if;
  end loop;
  insert into responses(link_id, ratings, remarks, open_answers)
    values (v_link.id, p_ratings, coalesce(p_remarks,'{}'::jsonb), coalesce(p_open,'{}'::jsonb));
  update links set answered_at = now() where id = v_link.id;
end $$;

revoke all on function get_link(text) from public;
revoke all on function submit_response(text, jsonb, jsonb, jsonb) from public;
grant execute on function get_link(text) to anon, authenticated;
grant execute on function submit_response(text, jsonb, jsonb, jsonb) to anon, authenticated;

-- ---------- convenience view for the dashboard ----------
create or replace view link_overview as
  select l.id, l.code, l.contact, l.email, l.depts, l.created_at, l.opened_at, l.answered_at,
         c.id as customer_id, c.company, c.country,
         r.ratings, r.remarks, r.open_answers, r.submitted_at
  from links l
  join customers c on c.id = l.customer_id
  left join responses r on r.link_id = l.id;
grant select on link_overview to authenticated;
