# Terraria server that runs inside a Docker container

This Docker image combines TShock and Terracord in a single, configurable image.

### Usage

Basic usage is as follows:
```sh
docker run \
  -p 0.0.0.0:7777:7777 \
  -p 0.0.0.0:7878:7878 \
  -e WORLD_FILENAME=docker.wld \
  -e TERRACORD_ENABLED=true \
  -e TERRACORD_BOT_TOKEN="<bot token>" \
  -e TERRACORD_CHANNEL_ID="<channel id>" \
  -e TERRACORD_OWNER_ID="<owner id>" \
  -v $(pwd)/terraria_data/worlds:/tshock/worlds \
  -v $(pwd)/terraria_data/plugins:/plugins \
  -v $(pwd)/terraria_data/logs:/tshock/logs \
  $@ \
  --name terraria-server \
  -it \
  --rm \
  didstopia/terraria:latest
```

Note that the Terracord integration is entirely option and disabled by default.

### Issues

If you need help, have questions or bug submissions, feel free to contact me **@Dids** on Twitter, and on the *Rust Server Owners* Slack community.
