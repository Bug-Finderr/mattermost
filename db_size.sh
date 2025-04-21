#!/bin/bash

PG_CONTAINER=$(docker ps | grep postgres | awk '{print $1}')

echo -e "==== Mattermost DB Stats ====\n"

DB_SIZE=$(docker exec $PG_CONTAINER psql -U mmuser -d mattermost_test -t -c \
  "SELECT pg_size_pretty(pg_database_size('mattermost_test'));")
echo "Total DB Size: ${DB_SIZE// /}"

echo -e "\n==== Table Stats ====\n"
printf "%-20s | %-15s | %-12s\n" "Table Name" "Total Size" "Row Count"
printf "%-20s-+-%-15s-+-%-12s\n" "--------------------" "---------------" "------------"

TABLES=("Users" "Teams" "Channels" "Posts" "Threads")

for TABLE in "${TABLES[@]}"; do
  STATS=$(docker exec $PG_CONTAINER psql -U mmuser -d mattermost_test -t -A -F'|' -c \
    "SELECT pg_size_pretty(pg_total_relation_size('$TABLE')), COUNT(*) FROM $TABLE;")
  IFS='|' read -r SIZE COUNT <<< "$STATS"
  SIZE=$(echo $SIZE | xargs)
  COUNT=$(printf "%'d" "$(echo $COUNT | xargs)")
  printf "%-20s | %-15s | %-12s\n" "$TABLE" "$SIZE" "$COUNT"
done
