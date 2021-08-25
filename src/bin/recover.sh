#!/bin/bash

dir=$(dirname "$0")
source $dir/functions.sh

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -g|--gpu) gpu="$2"; shift ;;
        -h|--help) help=1 ;;
        *) xecho $RED "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ ${help+x} ]; then
    echo "Arguments
    --gpu           # GPU ID e.g. 0"
    exit
fi

fetch_pids() {
    local gpu_nvsmi="$1"
    local nvsmi_query=`nvidia-smi $gpu_nvsmi -q -x | grep pid | sed -e 's/<pid>//g' -e 's/<\/pid>//g' -e 's/^[[:space:]]*//'`

    if [[ "$nvsmi_query" ]]; then
        ps --no-headers -up `echo "$nvsmi_query"`
        return 1
    else
        xecho $GREEN "No processes to kill"
        return 0
    fi
}

if [ -z ${gpu+x} ]; then
    xecho $RED "No GPU selected"
    exit 2
fi

gpu_id="$gpu"
gpu_selection="-i $gpu_id"

if [[ -z $(nvidia-smi $gpu_selection -q -d PERFORMANCE | grep "Unknown Error") ]]; then
    xecho $GREEN "Does not need to be recovered"
    exit 0
fi

containers=$(sudo docker ps | awk '{if(NR>1) print $NF}')
gpu_container=""

for container in $containers
do
    container_gpu_id=`docker exec $container bash -c 'echo $NVIDIA_VISIBLE_DEVICES'`

    if [[ "$gpu_id" == "$container_gpu_id" ]]; then
        gpu_container="$container"
        xecho $GREEN "Got GPU container: $gpu_container"
        break
    fi
done 

echo "Fetching PIDs for GPU: $gpu_id"
active_pids="$(fetch_pids "$gpu_selection")"

if [[ $? -eq 1 ]]; then
    while read -r process_line; do
        kill_name=`echo $process_line | awk '{ print $11 }'`
        kill_pid=`echo $process_line | awk '{ print $2 }'`
        xecho $YELLOW "Killing: $kill_name PID: $kill_pid"
        kill -9 "$kill_pid"
    done < <(echo $active_pids)
else
    echo "No processes to kill"
fi

killall X
killall Xorg
rm -f /tmp/.X0-lock

for ((i=0; i < 4; i++))
do
    xecho $YELLOW "GPU Reset attempt #$i - Stopping container: $gpu_container"
    docker stop "$gpu_container"
    xecho $YELLOW "Resetting GPU"
    nvidia-smi --gpu-reset $gpu_selection

    if [[ $? -eq 0 ]]; then
        xecho $GREEN "Starting original container"
        docker start "$gpu_container"
        break
    fi

    sleep 1
done

exit 124