import time
import argparse
import os
import json
from operator import itemgetter
from utilities import *

log, log_name = choose_log()

sorting = [
    {
        "label": "Highest efficiency",
        "data": sorted(log, key=itemgetter(1))
    },
    {
        "label": "Highest hashrate",
        "data": sorted(log, key=itemgetter(0))
    }
]

for sorted in sorting:
    print(f"\n{sorted['label']}")
    print("MH\tEfic.\tCore\tMem\tPL")
    sorted['data'].reverse()

    for item in sorted['data'][0:5]:
        print(f'{item[0]}\t{item[1]}\t{item[2]}\t{item[3]}\t{item[4]}')
