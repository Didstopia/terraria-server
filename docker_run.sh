#!/bin/bash

./docker_build.sh

docker run \
  -p 0.0.0.0:7777:7777 \
  -p 0.0.0.0:7878:7878 \
  -e WORLD_FILENAME=docker.wld \
  -v $(pwd)/terraria_data/worlds:/tshock/worlds \
  -v $(pwd)/terraria_data/plugins:/plugins \
  -v $(pwd)/terraria_data/logs:/tshock/logs \
  $@ \
  --name terraria-server \
  -it \
  --rm \
  didstopia/terraria:latest
