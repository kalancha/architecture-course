CREATE DATABASE IF NOT EXISTS bionicpro;

CREATE TABLE IF NOT EXISTS bionicpro.raw_telemetry (
  event_time DateTime,
  prosthesis_id String,
  movement_count UInt32,
  usage_seconds UInt32,
  battery_level UInt8,
  error_count UInt32
)
ENGINE = MergeTree
ORDER BY (prosthesis_id, event_time);

INSERT INTO bionicpro.raw_telemetry
  (event_time, prosthesis_id, movement_count, usage_seconds, battery_level, error_count)
VALUES
  ('2026-06-20 08:15:00', 'bp-arm-1001', 120, 3600, 92, 0),
  ('2026-06-20 12:45:00', 'bp-arm-1001', 180, 4200, 74, 1),
  ('2026-06-21 09:10:00', 'bp-arm-1001', 210, 5400, 81, 0),
  ('2026-06-21 18:30:00', 'bp-arm-1001', 96, 2400, 43, 2),
  ('2026-06-22 10:00:00', 'bp-hand-1002', 70, 1800, 88, 0),
  ('2026-06-22 15:20:00', 'bp-hand-1002', 84, 2100, 67, 0),
  ('2026-06-20 07:40:00', 'bp-leg-2001', 260, 7200, 96, 0),
  ('2026-06-21 11:30:00', 'bp-leg-2001', 310, 8100, 79, 0),
  ('2026-06-22 16:10:00', 'bp-leg-2001', 190, 4800, 58, 1),
  ('2026-06-20 13:00:00', 'bp-arm-3001', 130, 3300, 90, 0),
  ('2026-06-21 13:35:00', 'bp-arm-3001', 155, 3900, 73, 0),
  ('2026-06-22 17:50:00', 'bp-arm-3001', 122, 2700, 61, 1);
