#/usr/bin/env bash -x

docker run -d --rm --network=host --name prometheus-pushgateway prom/pushgateway
docker run -d --rm --network=host --name prometheus -v /home/zpatten/code/link/prometheus-data/:/prometheus-data prom/prometheus --config.file=/prometheus-data/prometheus.yml
