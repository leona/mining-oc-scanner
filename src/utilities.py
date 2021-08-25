import re, os, requests, time
from subprocess import check_output
from app import args, dir
import platform

platform = platform.system()
session = requests.Session()

def choose_log():
    logs = os.listdir(f"{dir}/data")
    logs = [i for i in logs if ".log" in i]
    log = input_options("log", logs)
    return load_log(logs[log]), logs[log]

def load_log(log):
    with open(f"{dir}/data/{log}") as f:
        content = f.readlines()

    content = [x.strip().split("\t") for x in content]
    return [[ float(i) for i in x] for x in content]

def input_options(name, options, item_key=None):
    if len(options) > 1:
        for key, item in enumerate(options):
            print(f"[ {key} ] - {item if not item_key else item[item_key]}")

        return int(input(f"Choose a {name} [0 - {len(options) - 1}]: "))

    return 0

def get_json(url):
    try:
        return session.get(url).json()
    except:
        dlog("Failed to get url:", url)

def timestamp():
    secondsSinceEpoch = time.time()
    timeObj = time.localtime(secondsSinceEpoch)

    return '%d-%d-%d--%d-%d-%d' % (
    timeObj.tm_mday, timeObj.tm_mon, timeObj.tm_year, timeObj.tm_hour, timeObj.tm_min, timeObj.tm_sec)

def unix_timestamp():
    return int(time.time())

def flog(level, device_id, *_args, write=True):
    if args.debug and level > 0:
        if write:
            wlog(f"{device_id}-debug", *_args)
        dlog(*_args)
        return
        
    if not args.debug and level > 0:
        return

    if write:
        wlog(device_id, *_args)

    dlog(*_args)

def wlog(device_id, *_args):
    _args = [str(item) for item in _args]
    f = open(f'{dir}/data/output-{device_id}.log', 'a')
    f.write(' '.join(_args) + '\n')
    f.close()

def dlog(*args):
    _timestamp = timestamp()
    args = (f"{_timestamp}\t",) + args + ("",)
    print(*args)

def split_range(arg):
    data = arg.split(",")

    return {
        "min": int(data[0]),
        "max": int(data[1])
    }

def str_to_float(value):
    return float(re.sub("[^0-9.]", "", value))

def str_to_int(value):
    return int(re.sub("[^0-9]", "", value))

def exec(cmd):
    flog(1, "exec", "Starting exec:", cmd, write=False)
    output = check_output(cmd, shell=True).decode()
    flog(1, "exec", output, write=False)
    return output

def exec_pl(id, pl, max_power):
    actual_pl = int(max_power * (pl / 100))
    flog(1, id, f"Setting GPU {id} pl: {actual_pl}w")
    return exec(f"nvidia-smi -pl {actual_pl} -i {id}")

def exec_oc(id, core, mem, fans=False):
    flog(1, id, f"Setting GPU {id} core: {core} mem: {mem}")

    if platform == "Windows":
        # Removed: -setPowerTarget:{id},{pl}
        return exec(f"{dir}/nvidia-inspector/nvidiaInspector.exe -setTempTarget:{id},0,80 -setFanSpeed:{id},65 -setBaseClockOffset:{id},0,{core} -setMemoryClockOffset:{id},0,{mem}")
    elif platform == "Linux":
        _fans = ""

        if fans:
            _fans = f"--fan {fans}"
        
        return exec(f"{dir}/src/bin/oc.sh --gpu {id} {_fans} --core {core} --mem {mem}")
    else:
        print("Unsupported platform")

def exec_fans(fans):
    flog(1, id, f"Setting fans to: {fans}")

    if platform == "Windows":
        # Removed: -setPowerTarget:{id},{pl}
        #return exec(f"{dir}/nvidia-inspector/nvidiaInspector.exe -setFanSpeed:{id},65")
        print("TODO")
    elif platform == "Linux":
        return exec(f"{dir}/src/bin/oc.sh --fan {fans}")
    else:
        print("Unsupported platform")


def exec_power_limits(id): 
    default_power = float(exec(f"nvidia-smi -i {id} --query-gpu=power.default_limit --format=csv,noheader,nounits").strip())
    max_power = float(exec(f"nvidia-smi -i {id} --query-gpu=power.max_limit --format=csv,noheader,nounits").strip())
    return default_power, max_power

def exec_avg_power_draw(id, ):
    power_draws = []

    for i in range(0, 9):
        power_draw = float(exec(f"nvidia-smi -i {id} --query-gpu=power.draw --format=csv,noheader,nounits").strip())
        power_draws.append(power_draw)
        time.sleep(0.2)

    return int(sum(power_draws) / len(power_draws))
