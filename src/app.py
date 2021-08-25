from utilities import *
import time
import argparse
import os
import json
from operator import itemgetter
from dotenv import load_dotenv

dir = os.path.dirname(os.path.realpath(__file__)) + "/.."
load_dotenv(dotenv_path=f"{dir}/config.env")

parser = argparse.ArgumentParser(description="Auto Mining OC")
parser.add_argument('--restore', type=int, default=0)
parser.add_argument('--view', type=int, default=0)
parser.add_argument('--debug', type=int, default=os.getenv("DEBUG") or 0)
parser.add_argument('--pl', type=str, default=os.getenv("PL") or "65,80")
parser.add_argument('--core', type=str, default=os.getenv("CORE") or "-200,100")
parser.add_argument('--mem', type=str, default=os.getenv("MEM") or "-100,1000")
parser.add_argument('--step', type=int, default=os.getenv("STEP") or 50)
parser.add_argument('--mem-sleep', type=int, default=os.getenv("MEM_SLEEP") or 20)
parser.add_argument('--core-sleep', type=int, default=os.getenv("CORE_SLEEP") or 40)
parser.add_argument('--api', type=str, default=os.getenv("API") or"http://127.0.0.1:22333")

args = parser.parse_args()

if __name__ == '__main__':
    print("Started OC Scanner. Config:", args)

    if args.view == 1:
        import viewer
    else:
        import oc
