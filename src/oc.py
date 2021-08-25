import os, json, argparse, time
from utilities import *
from app import args

data = get_json(args.api + "/api/v1/status")
devices = data['miner']['devices']

pl = split_range(args.pl)
core = split_range(args.core)
mem = split_range(args.mem)

if args.restore == 1:
    log, log_name = choose_log()
    last_item = log[-1]
    device_id = str_to_int(log_name)
    device = devices[device_id]

    current = {
        "core": int(last_item[2]),
        "mem": int(last_item[3]),
        "pl": int(last_item[4])
    }
else:
    device_id = input_options("device", devices, item_key='info')
    device = devices[device_id]

    current = {
        "core": core['min'],
        "mem": mem['min'],
        "pl": pl['min']
    }

def iterate_clocks(values):
    sleep = args.mem_sleep

    if values['mem'] == mem['max']:
        if values['core'] == core['max']:
            values['core'] = core['min']
            values['mem'] = mem['min']
            values['pl'] += 1
        else:
            values['mem'] = mem['min']
            values['core'] += args.step

        sleep = args.core_sleep
    else:
        values['mem'] += args.step

    if values['pl'] > pl['max']:
        return False

    return sleep

def apply(sleep):
    exec_oc(device_id, current['core'], current['mem'])
    time.sleep(sleep)

def remaining_seconds():
    total_sleep = 0
    cloned = dict(current)

    while True:
        sleep = iterate_clocks(cloned)

        if not sleep:
            return total_sleep

        total_sleep += sleep


default_power, max_power = exec_power_limits(device_id)
dlog("Max power draw:", max_power, "Default power draw:", default_power)
exec_pl(device_id, current['pl'], default_power)
exec_fans(100)
apply(args.core_sleep)
dlog("MH\tEffic.\tCore\tMem\tPL\tRemaining")

while True:
    data = get_json(args.api + "/api/v1/status")
    device = data['miner']['devices'][device_id]
    hashrate = str_to_float(device['hashrate'])
    efficiency = hashrate / (default_power * (current['pl'] / 100))

    core_val = current['core']
    mem_val = current['mem']
    pl_val = current['pl']

    remaining = round(remaining_seconds() / 60 / 60, 2)
    output_log = f'{hashrate:.1f}\t{efficiency:.4f}\t{core_val}\t{mem_val}\t{pl_val}'

    wlog(device_id, output_log)
    dlog(f'{output_log}\t{remaining} hours')

    old_pl = int(current['pl'])
    sleep = iterate_clocks(current)

    if not sleep:
        dlog("Finished. Applying stock clocks.")
        exec_oc(device_id, 0, 0)
        exec_pl(device_id, 100, default_power)
        break

    if old_pl != current['pl']:
        exec_pl(device_id, current['pl'], default_power)

    apply(sleep)
