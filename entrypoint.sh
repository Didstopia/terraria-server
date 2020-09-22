#!/usr/bin/env bash

# Based on ryansheehan's work here:
# https://github.com/ryansheehan/terraria/blob/master/tshock/bootstrap.sh

# Enable debugging
# set -x

# Print the user we're currently running as
echo "Running as user: $(whoami)"

echo "\nBootstrap:\nworld_file_name=${WORLD_FILENAME}\nconfigpath=${CONFIG_PATH}\nlogpath=${LOG_PATH}\n"

# Configure Terracord if it's enabled
if [ "$TERRACORD_ENABLED" = "true" ]; then
  echo "Setting up Terracord.."
  TERRACORD_XML=/tshock/tshock/Terracord/terracord.xml
  cp -fr /tshock/Terracord.dll /tshock/ServerPlugins/

  # Override message silencing preferences
  xmlstarlet ed --inplace -u '/configuration/silence/@broadcasts' -v "${TERRACORD_SILENCE_BROADCASTS}" ${TERRACORD_XML}
  xmlstarlet ed --inplace -u '/configuration/silence/@chat' -v "${TERRACORD_SILENCE_CHAT}" ${TERRACORD_XML}
  xmlstarlet ed --inplace -u '/configuration/silence/@saves' -v "${TERRACORD_SILENCE_SAVES}" ${TERRACORD_XML}
  xmlstarlet ed --inplace -u '/configuration/announce/@reconnect' -v "${TERRACORD_ANNOUNCE_RECONNECT}" ${TERRACORD_XML}

  # Setup Discord bot token
  if [ ! -z "$TERRACORD_BOT_TOKEN" ]; then
    xmlstarlet ed --inplace -u '/configuration/bot/@token' -v "${TERRACORD_BOT_TOKEN}" ${TERRACORD_XML}
    echo "Terracord bot token set"
  else
    echo "ERROR: Missing Terracord bot token (TERRACORD_BOT_TOKEN)"
    exit 1
  fi

  # Setup Discord bot channel
  if [ ! -z "$TERRACORD_CHANNEL_ID" ]; then
    xmlstarlet ed --inplace -u '/configuration/channel/@id' -v "${TERRACORD_CHANNEL_ID}" ${TERRACORD_XML}
    echo "Terracord channel id set"
  else
    echo "ERROR: Missing Terracord channel id (TERRACORD_CHANNEL_ID)"
    exit 1
  fi

  # Setup Discord bot owner
  if [ ! -z "$TERRACORD_OWNER_ID" ]; then
    xmlstarlet ed --inplace -u '/configuration/owner/@id' -v "${TERRACORD_OWNER_ID}" ${TERRACORD_XML}
    echo "Terracord owner id set"
  else
    echo "ERROR: Missing Terracord owner id (TERRACORD_OWNER_ID)"
    exit 1
  fi
else
  echo "Terracord not setup, disabling.."
  rm -fr /tshock/ServerPlugins/Terracord.dll
fi

# Copy plugins if any exist
if [ ! "$(ls -A /plugins)" ]; then
  echo "Setting up plugins.."
  cp -Rfv /plugins/* /tshock/ServerPlugins
fi

# Configure and start the server
if [ -z "${WORLD_FILENAME}" ]; then
  echo "No world file specified in environment WORLD_FILENAME."
  if [ -z "$@" ]; then 
    echo "Running server in interactive mode.."
  else
    echo "Running server with additional parameters: $@"
  fi
  mono --server --gc=sgen -O=all TerrariaServer.exe -configpath "${CONFIG_PATH}" -logpath "${LOG_PATH}" "$@"
else
  echo "Environment WORLD_FILENAME specified"
  WORLD_PATH="${CONFIG_PATH}/${WORLD_FILENAME}"
  if [ -f "${WORLD_PATH}" ]; then
    echo "Loading world ${WORLD_FILENAME}.."
    mono --server --gc=sgen -O=all TerrariaServer.exe -configpath "${CONFIG_PATH}" -logpath "${LOG_PATH}" -world "${WORLD_PATH}" "$@"
  else
    echo "Unable to locate world path: ${WORLD_PATH}.\nPlease make sure your world path is properly mounted: -v <path_to_world_file>:/tshock/worlds"
    exit 1
  fi
fi
