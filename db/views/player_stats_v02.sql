SELECT
  users.id AS user_id,
  users.name,
  users.country,
  COUNT(games.id) AS games_played,
  COUNT(games.id) FILTER (WHERE participants.winner) AS games_won,
  COALESCE(ROUND(COUNT(games.id) FILTER (WHERE participants.winner) * 100.0
    / NULLIF(COUNT(games.id), 0), 1), 0.0) AS win_percentage,
  COALESCE(SUM(EXTRACT(EPOCH FROM (games.finished_at - games.started_at))), 0)::bigint AS play_seconds
FROM users
LEFT JOIN participants ON participants.user_id = users.id
LEFT JOIN games ON games.id = participants.game_id
  AND games.started_at IS NOT NULL
  AND games.finished_at IS NOT NULL
GROUP BY users.id, users.name, users.country
