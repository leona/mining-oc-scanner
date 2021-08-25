/usr/bin/docker run -d --restart=always --gpus all --name miner nxie/aio-miner nbminer/nbminer -a ethash -o stratum+tcp://eth-eu1.nanopool.org:9999 -u address.miner1/email@email.com
/root/oc.sh --setup
/root/oc.sh --fan 95
/root/oc.sh --gpu 0 --pl 312 --mem 900 --core -250
/root/oc.sh --gpu 1 --pl 312 --mem 850 --core -250
/root/oc.sh --gpu 2 --pl 312 --mem 1000 --core -200
/root/oc.sh --gpu 3 --pl 312 --mem 1100 --core -200