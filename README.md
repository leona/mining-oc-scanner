# Mining Overclock Scanner

These scripts automatically iterate through a range of overclocks for Nvidia GPUs and display both the highest and most efficient results. The hashrate is read from NBMiner so any of its algos are supported. 

Supported and tested on Windows 10 and Ubuntu 20.04.

The process can take a long time if you specify a wide range, but it can be extremely useful to find a good balance. Results are split into high hashrate and high efficiency.

## NOTE
I'm not responsible if you damage your GPU using this.

## Screenshots
Scanning

![image](https://raw.githubusercontent.com/leona/mining-oc-scanner/master/data/screenshots/resume.png)

Results

![image](https://raw.githubusercontent.com/leona/mining-oc-scanner/master/data/screenshots/stats.png)

## Prerequisites
- Run NBMiner before starting the scanner

## Prerequisites - Linux
- Install pip `apt install python3-pip`
- Run `pip3 install -r requirements.txt` within this directory

## Prerequisites - Windows
- Download [nvidia-inspector](https://www.guru3d.com/files-details/nvidia-inspector-download.html) and place it in this directory within a folder called nvidia-inspector
- Install python 3.9 from the Microsoft store
- Run `pip3 install -r requirements.txt` within this directory in a CMD window

## Running on Linux
- Start scanning `./run.sh --mem -100,1400 --core -400,100 --pl 70,80`
- View results from a log file `./run.sh --view 1`
- Restore and continue scan from a log file `./run.sh --restore 1`

## Running on Windows
Click on one the .bat files in this directory. See below for what they do.
- `run.bat` - Starts the scanner with the default settings.
- `continue.bat` - choose from a log file to continue a scan from. Useful in case of a crash or just stopping the scan.
- `view.bat` - View the most efficient results and highest results from a log

## Command line arguments
In a privileged CMD window you can pass more options e.g. `python3 src/app.py --core -200,100 --mem 0,1400 -pl 70,90`
- `--core` - min/max range to iterate core clock e.g. `--core -400,100`
- `--mem` - min/max range to iterate mem clock e.g. `--mem 0,1400`
- `--pl` - min/max range to iterate % power limit e.g. `--pl 70,80`
- `--step` - amount to increase per iteration of core/mem e.g. `--step 25`
- `--core-sleep` - amount of seconds to wait after setting core clock e.g. `--core-sleep 40`
- `--mem-sleep` - amount of time to wait after setting memory clock e.g. `--mem-sleep 15`
- `--api` - NBMiner API URL e.g. `http://127.0.0.1:22333`
- `--view` - Show stats for a specific log file e.g. `--view 1`
- `--restore` - Continue scan from a log file e.g. `--restore 1`
- `--debug` - Display debug messages e.g. `--debug 1`

## config.env options
You can also place the above options in the config.env file. They need to be uppercase and camelized.
