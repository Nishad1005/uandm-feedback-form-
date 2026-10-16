-- Migration 002: contact book, WhatsApp numbers, customer merge.
-- Run once in Supabase → SQL Editor (after schema.sql). Safe to re-run.

create table if not exists contacts (
  id           uuid primary key default gen_random_uuid(),
  customer_id  uuid not null references customers(id) on delete cascade,
  name         text not null,
  name_key     text generated always as (lower(regexp_replace(btrim(name), '\s+', ' ', 'g'))) stored,
  phone        text not null default '',
  email        text not null default '',
  status       text not null default '',     -- role at the customer, e.g. MERCHANDISING / OWNER / QA
  location     text not null default '',
  created_at   timestamptz not null default now(),
  unique (customer_id, name_key)
);
create index if not exists contacts_customer_idx on contacts(customer_id);

alter table links add column if not exists contact_id uuid references contacts(id) on delete set null;
alter table links add column if not exists phone text not null default '';

alter table contacts enable row level security;
drop policy if exists staff_all on contacts;
create policy staff_all on contacts for all to authenticated using (true) with check (true);

-- dashboard view now carries phone + contact_id
create or replace view link_overview as
  select l.id, l.code, l.contact, l.email, l.phone, l.contact_id, l.depts, l.created_at, l.opened_at, l.answered_at,
         c.id as customer_id, c.company, c.country,
         r.ratings, r.remarks, r.open_answers, r.submitted_at
  from links l
  join customers c on c.id = l.customer_id
  left join responses r on r.link_id = l.id;
grant select on link_overview to authenticated;

-- Merge one customer into another (moves contacts + links, deletes the source).
create or replace function merge_customers(p_source uuid, p_target uuid)
returns void language plpgsql security definer set search_path = public as $$
declare rec record;
begin
  if p_source = p_target then return; end if;
  if auth.role() <> 'authenticated' then raise exception 'not allowed'; end if;
  -- contacts: move, but if the same name already exists at the target, point links at the existing one
  for rec in select * from contacts where customer_id = p_source loop
    if exists (select 1 from contacts t where t.customer_id = p_target and t.name_key = rec.name_key) then
      update links set contact_id = (select id from contacts t where t.customer_id = p_target and t.name_key = rec.name_key)
        where contact_id = rec.id;
      update contacts t set phone = coalesce(nullif(t.phone,''), rec.phone), email = coalesce(nullif(t.email,''), rec.email),
                            status = coalesce(nullif(t.status,''), rec.status), location = coalesce(nullif(t.location,''), rec.location)
        where t.customer_id = p_target and t.name_key = rec.name_key;
      delete from contacts where id = rec.id;
    else
      update contacts set customer_id = p_target where id = rec.id;
    end if;
  end loop;
  update links set customer_id = p_target where customer_id = p_source;
  delete from customers where id = p_source;
end $$;
revoke all on function merge_customers(uuid, uuid) from public;
grant execute on function merge_customers(uuid, uuid) to authenticated;
