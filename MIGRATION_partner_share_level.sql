-- Migration: Add partner_share_level column to song_events
-- Run this in Supabase SQL Editor

-- Add column with default value
ALTER TABLE song_events
ADD COLUMN IF NOT EXISTS partner_share_level TEXT NOT NULL DEFAULT 'MINIMAL';

-- Add CHECK constraint to enforce allowed values
ALTER TABLE song_events
ADD CONSTRAINT partner_share_level_check 
CHECK (partner_share_level IN ('MINIMAL', 'FULL'));

-- Backfill existing rows (should already be MINIMAL due to DEFAULT, but explicit update for safety)
UPDATE song_events
SET partner_share_level = 'MINIMAL'
WHERE partner_share_level IS NULL OR partner_share_level NOT IN ('MINIMAL', 'FULL');

-- Verify: Check that all rows have valid values
-- SELECT id, share_with_partner, partner_share_level FROM song_events LIMIT 10;

