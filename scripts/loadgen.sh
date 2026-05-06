#!/bin/sh  
echo "Starting load generator..."
while true; do
  curl -s http://app1:8001/text > /dev/null 2>&1
  curl -s http://app1:8001/time > /dev/null 2>&1
  curl -s http://app1:8001/health > /dev/null 2>&1
  curl -s http://app2:8002/text > /dev/null 2>&1
  curl -s http://app2:8002/time > /dev/null 2>&1
  curl -s http://app2:8002/health > /dev/null 2>&1
  sleep 5
done