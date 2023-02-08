#!/bin/bash

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

apt-get -o DPkg::Lock::Tieout=-1 update -qq
curl -fsSL https://get.docker.com -o get-docker.sh

while ! command_exists docker
do
    echo "installing docker engine"
    /bin/sh ./get-docker.sh
done

while ! command_exists jq
do
    echo "installing jq for reading browsers.json"
    apt-get -y install jq
done

docker rm `docker ps -a -q --filter name=selenoid-ui` -f
docker rm `docker ps -a -q --filter name=selenoid` -f

systemctl daemon-reload
systemctl stop docker
systemctl enable --now docker
systemctl start docker

mkdir -p /home/selenoid/logs /home/selenoid/video

if [ ! -f /home/selenoid/browsers.json ]
then
    echo "Downloading browsers.json"
    curl -fsSL https://raw.githubusercontent.com/segrid/selenoid-setup/main/browsers.json -o /home/selenoid/browsers.json
fi

echo "Pulling docker images"
docker pull public.ecr.aws/orienlabs/selenoid:latest
docker pull public.ecr.aws/orienlabs/selenoid-ui:latest
docker pull public.ecr.aws/orienlabs/video-recorder:latest
jq -r '.[].versions[].image' /home/selenoid/browsers.json | while read line
do
    echo "Pulling image $line"
    docker pull $line
done

totalmem=$(expr `vmstat -s | grep 'total memory' | tr -s " " " " | cut -d " " -f2` / 1024 / 1024)
echo "Max $totalmem sessions are allowed on this machine"

docker run -d                                   \
--restart always                                \
--name selenoid                                 \
-p 4444:4444                                    \
-v /var/run/docker.sock:/var/run/docker.sock    \
-v /home/selenoid/:/etc/selenoid/               \
-v /home/selenoid/logs/:/opt/selenoid/logs/ 	\
-v /home/selenoid/video/:/opt/selenoid/video/  	\
-e OVERRIDE_VIDEO_OUTPUT_DIR=/home/selenoid/video/   \
public.ecr.aws/orienlabs/selenoid:latest        \
-log-output-dir /opt/selenoid/logs              \
-video-output-dir /opt/selenoid/video           \
-limit $totalmem                                \
-timeout 20m                                    \
-service-startup-timeout 5m                     \
-session-attempt-timeout 5m                     \
-retry-count 10                                 \
-video-recorder-image public.ecr.aws/orienlabs/video-recorder:latest \
-conf /etc/selenoid/browsers.json

DOCKER_GATEWAY_ADDR=`docker inspect selenoid -f {{.NetworkSettings.Gateway}}`
echo $DOCKER_GATEWAY_ADDR

docker run -d      \
--restart always   \
--name selenoid-ui \
--link selenoid    \
-p 8080:8080       \
public.ecr.aws/orienlabs/selenoid-ui:latest \
--selenoid-uri=http://selenoid:4444

echo "Selenoid Grid UI: http://`hostname -I | awk '{print $1}'`:8080"
echo "Webdriver URL: http://`hostname -I | awk '{print $1}'`:4444/wd/hub"