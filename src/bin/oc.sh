#!/bin/bash

dir=$(dirname "$0")
source $dir/functions.sh

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -g|--gpu) gpu="$2"; shift ;;
        -c|--core) core="$2"; shift ;;
        -m|--mem) mem="$2"; shift ;;
        -f|--fan) fan="$2"; shift ;;
        -p|--pl) pl="$2"; shift ;;
        -s|--setup) setup=1 ;;
        -h|--help) help=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ ${help+x} ]; then
    echo "Arguments
    --gpu           # GPU ID e.g. 0
    --core          # Core clock scan range e.g. -400,100
    --mem           # Mem clock scan range e.g. -100,1400
    --fan           # Set static fan speed % on all GPUs e.g. 100
    --pl            # Power limit a GPU in watts e.g. 350
    --setup         # Run X setup. It should automatically do this."
    exit
fi

NVS_TIMEOUT=10

call_nvidia_settings() {
	local args="$1"
	local exitcode
	local result
	[[ -z "$args" ]] && return 0
	echo -n "${RED}" # set color to red
	result=`DISPLAY=:0 timeout --foreground -s9 $NVS_TIMEOUT nvidia-settings -c :0  $args 2>&1 | grep -v "^$"`
	exitcode=$?
	if [[ $exitcode -eq 0 ]]; then
		echo "${NOCOLOR}$result"
	else
		[[ ! -z "$result" ]] && echo "$result"
		[[ $exitcode -ge 124 ]] && echo "nvidia-settings failed by timeout (exitcode=$exitcode)${NOCOLOR}" || echo "(exicode=$exitcode)${NOCOLOR}"
        setup_screen      
	fi
	return $exitcode
}

setup_screen() {
    screen -X -S display2 quit &
    killall X
    killall Xorg
    rm -f /tmp/.X0-lock
    # Maybe replace Driver "dummy" in Section "Device"
    nvidia-xconfig -a --allow-empty-initial-configuration --cool-bits=31 --use-display-device="DFP-0" --connected-monitor="DFP-0"
    sed -i s/"DPMS"/"NODPMS"/ /etc/X11/xorg.conf
    screen -A -m -d -S display2 sudo X :0
    nvidia-smi -pm 1
}

if [ ${setup+x} ] || ! sudo su -c "screen -list" | grep -q "display2"; then
    xecho $YELLOW "Setting up"
    setup_screen
fi

DISPLAY=:0
export DISPLAY=:0
NUM_GPUS=`call_nvidia_settings "-q gpus" | grep -c 'gpu:'`

core_mem_string() {
    local nvs=""
    local gpu_id="$1"

    #gpu_name="$(sudo nvidia-smi -i 0 --query-gpu=name --format=csv,noheader | tail -n1)"
    gpu_plevel=`call_nvidia_settings "-c :0 -q GPUPerfModes" | grep -oP "'GPUPerfModes'.*\[gpu\:$gpu_id\].* perf=\K[0-9]+"`

    if [ ${core+x} ]; then
        core="$(($core * 2))"
        nvs+="-a [gpu:$gpu_id]/GPUGraphicsClockOffset[$gpu_plevel]=$core -a [gpu:$gpu_id]/GPUGraphicsClockOffsetAllPerformanceLevels=$core "
    fi

    if [ ${mem+x} ]; then
        mem="$(($mem * 2))"
        nvs+="-a [gpu:$gpu_id]/GPUMemoryTransferRateOffset[$gpu_plevel]=$mem -a [gpu:$gpu_id]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$mem "
    fi

    echo "$nvs"
}


if [ ${pl+x} ]; then
    xecho $YELLOW "Setting PL"

    if [ ${gpu+x} ]; then
        nvidia-smi -pl $pl -i $gpu
    else
        for ((i=0; i < NUM_GPUS; i++))
        do
            nvidia-smi -pl $pl -i $i
        done
    fi
fi

if [ ${core+x} ] || [ ${mem+x} ]; then
    xecho $YELLOW "Getting plevel"

    if [ ${gpu+x} ]; then
        nvs=$(core_mem_string $gpu)
    else
        nvs=""
        for ((i=0; i < NUM_GPUS; i++))
        do
            nvs+=$(core_mem_string $i)
        done
    fi

    xecho $YELLOW "Applying core/mem clocks"
    call_nvidia_settings "$nvs"
    xecho $GREEN "Finished"
fi

if [ ${fan+x} ]; then
    NUM_FANS=`call_nvidia_settings "-q fans" | grep -c 'fan:'`
    nvs=""

    xecho $YELLOW "Applying fans"
    for ((i=0; i < NUM_GPUS; i++))
    do
        nvs+="-a [gpu:$i]/GPUFanControlState=1 "
    done

    for ((i=0; i < NUM_FANS; i++))
    do
        nvs+="-a [fan:$i]/GPUTargetFanSpeed=$fan "
    done

    call_nvidia_settings "--verbose=all $nvs"
    xecho $GREEN "Finished"
fi

