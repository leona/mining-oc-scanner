#!/bin/bash

dir=$(dirname "$0")
source $dir/functions.sh

if ! command -v jq &> /dev/null; then
    xecho $RED "Command jq not found. Install with ${BLUE}apt install jq"
    exit
fi

while [ 1 ]; do
    containers=$(docker ps | awk '{if(NR>1) print $NF}')
    hashrates=""

    for container in $containers
    do
        container_gpu_id=`docker exec $container bash -c 'echo $NVIDIA_VISIBLE_DEVICES'`

        if [[ -z "$container_gpu_id" ]]; then
            continue
        fi

        container_ip=`docker exec $container bash -c 'hostname --ip-address'`
        url="http://$container_ip:22333/api/v1/status"

        response="$(curl -X GET $url 2>/dev/null)"

        for key in $(jq '.miner.devices | keys | .[]' <<< "$response"); do
            values=$(jq -r ".miner.devices[$key]" <<< "$response");
            hashrate=$(jq -r '.hashrate' <<< "$values");
            gpu_name=$(jq -r '.info' <<< "$values");
            stats=$(nvidia-smi -i $container_gpu_id --query-gpu=temperature.gpu,power.draw,clocks.mem,clocks.gr,gpu_bus_id --format=csv,noheader)
            temperature=$(echo "$stats" | awk -F', ' '{ print $1 }')
            power=$(echo "$stats" | awk -F', ' '{ print $2 }')
            mem=$(echo "$stats" | awk -F', ' '{ print $3 }')
            core=$(echo "$stats" | awk -F', ' '{ print $4 }')
            bus_id=$(echo "$stats" | awk -F', ' '{ print $5 }' | awk -F'00000000:' '{ print $2 }')
            vendor=$(lspci -vnn | grep "$bus_id" -A 12 | grep "Subsystem" | xargs | awk -F'Subsystem: ' '{ print $2 }')
            hashrates+="$container_gpu_id\t$container\t$gpu_name\t$hashrate\t\t${temperature}c\t\t${power}\t${core}\t${mem}\t$vendor\n"
        done
    done

    cls
    xecho $YELLOW "Polling: /api/v1/status"
    echo -e "${BLUE}GPU ID\tContainer ID\tGPU\t\t\tHashrate\tTemperature\tPower\t\tCore\t\tMemory\t\tVendor${NOCOLOR}"
    echo -e "$hashrates"
    sleep 2
done