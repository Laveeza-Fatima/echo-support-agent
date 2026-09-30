-- Echo: Supabase setup
-- Run once in Supabase → SQL Editor → New query → paste → Run.

-- 1. Vector search
create extension if not exists vector;

-- Knowledge chunks (Gemini text-embedding-004 = 768 dimensions)
create table if not exists documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(768)
);

-- Similarity search used by the n8n Supabase Vector Store node
create or replace function match_documents (
  query_embedding vector(768),
  match_count int default null,
  filter jsonb default '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
#variable_conflict use_column
begin
  return query
  select
    id,
    content,
    metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- 2. Questions the agent couldn't answer (the "learning queue")
create table if not exists knowledge_gaps (
  id bigserial primary key,
  question text not null,
  customer_ref text,                 -- chat session / phone, so the answer can be sent back
  wa_message_id text,                -- id of the WhatsApp message sent to the owner (their reply points to it)
  status text not null default 'open', -- open | answered
  answer text,
  created_at timestamptz not null default now(),
  answered_at timestamptz
);

-- 3. Handy view for the weekly report: what customers ask that you haven't documented
create or replace view knowledge_gap_report as
select status, count(*) as questions, min(created_at) as oldest
from knowledge_gaps
group by status;

-- Fast lookup when the owner replies on WhatsApp
create index if not exists knowledge_gaps_wa_message_id_idx on knowledge_gaps (wa_message_id);
