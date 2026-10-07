-- Per-activation archetype pick from generate_insight (one fixed-list choice per event).
-- Additive and nullable: existing rows stay as they are and keep being scored by keywords in the app.
alter table public.shadow_insights
  add column if not exists archetype text,
  add column if not exists archetype_confidence text,
  add column if not exists archetype_evidence text;

alter table public.shadow_insights
  drop constraint if exists shadow_insights_archetype_confidence_check,
  add constraint shadow_insights_archetype_confidence_check
    check (archetype_confidence is null or archetype_confidence in ('low', 'medium', 'high'));
