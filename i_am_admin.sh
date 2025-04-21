#!/bin/bash

set -e
set -o pipefail

echo -e "\nAdding sysadmin to teams"

pushd server > /dev/null 2>&1

TEAMS=$(bin/mmctl team list --format json --local | jq -r '.[].id')
tTotal=$(echo "$TEAMS" | wc -w | xargs)
tCnt=0

for t in $TEAMS; do
  tCnt=$((tCnt + 1))
  printf "Progress: %d/%d teams\r" $tCnt $tTotal
  bin/mmctl team users add $t sysadmin --local > /dev/null 2>&1
done

echo -ne "\rProgress: $tTotal/$tTotal teams... Done.\n"
echo -e "\nAdding sysadmin to channels"

tCnt=0

for t in $TEAMS; do
  tCnt=$((tCnt + 1))

  CHANNELS=$(bin/mmctl channel list $t --format json --local 2>/dev/null | jq -r '.[].id')
  cTotal=$(echo "$CHANNELS" | wc -w | xargs)
  cCnt=0

  for c in $CHANNELS; do
    cCnt=$((cCnt + 1))
    printf "\033[KProgress: Team %d/%d, Channel %d/%d\r" $tCnt $tTotal $cCnt $cTotal
    bin/mmctl channel users add "$t:$c" sysadmin --local > /dev/null 2>&1
  done
done

popd > /dev/null 2>&1

echo -ne "\033[K\rProgress: Team $tTotal/$tTotal, Channels processed... Done.\n"
echo -e "\nEnjoy!\n"
