#!/bin/bash -x

set -o errexit
set -o nounset

INTERVAL_LENGTH=$(lq "GET status\nColumns: interval_length")

lq "GET services\nColumns: host_name description check_interval\nFilter: check_interval >= 60" | while IFS=';' read -r host service interval ; do
    INTERVAL=$(( interval * INTERVAL_LENGTH ))
    NEXT=$(shuf -i 1-${INTERVAL} -n 1)
    NOW=$(date +%s)
    THEN=$(( NOW + NEXT ))
    echo "COMMAND [${NOW}] SCHEDULE_FORCED_SVC_CHECK;${host};${service};${THEN}" | lq
done
