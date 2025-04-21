#!/bin/bash

echo "Starting mmctl benchmark..."

results=""
bg_pids=()
CLEAN_STOP="make stop-server > /dev/null 2>&1 && make clean-docker > /dev/null 2>&1"

cleanup() {
  echo -e "\nCleaning up..."
  eval $CLEAN_STOP
  
  for pid in "${bg_pids[@]}"; do
    kill $pid 2>/dev/null
    wait $pid 2>/dev/null
  done
  exit 1
}

trap cleanup SIGINT

show_dots() {
  while true; do
    echo -n "."
    sleep 2
  done
}

wait_for_server() {  
  for ((j=1; j<=10; j++)); do
    if [ -e "/var/tmp/mattermost_local.socket" ]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

pushd server > /dev/null 2>&1

for i in {1..5}; do
  echo -e "\nRun #$i:"
  echo -n "Heating up server "
  
  eval $CLEAN_STOP && make run-server > /dev/null 2>&1 && echo "✅"
  
  wait_for_server || { echo "Server failed to start, skipping run #$i"; continue; }
  
  echo -n "Running mmctl "
  
  show_dots &
  dots_pid=$!
  bg_pids+=($dots_pid)
  
  start_time=$(date +%s.%N)
  bin/mmctl sampledata --teams 2 --posts-per-channel 1000 --local > /dev/null 2>&1
  end_time=$(date +%s.%N)
  
  kill $dots_pid 2>/dev/null
  wait $dots_pid 2>/dev/null
  bg_pids=(${bg_pids[@]/$dots_pid})
  echo " done"
  
  elapsed=$(printf "%.2f" $(echo "$end_time - $start_time" | bc))
  results="$results $elapsed,"
  
  echo "Run #$i completed in $elapsed seconds"
done
  
eval $CLEAN_STOP

popd > /dev/null 2>&1

echo -e "\nResults:${results%,}\n"
