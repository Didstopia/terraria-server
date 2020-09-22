# Based on ryansheehan's work here:
# https://github.com/ryansheehan/terraria/blob/master/tshock/Dockerfile

# Build TShock
FROM mono:6.8 AS tshock
LABEL maintainer="Didstopia <support@didstopia.com>"
ENV TSHOCK_VERSION=v4.4.0-pre12
ENV BUILD_MODE=Release
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    git && \
    nuget update -self
RUN git clone --recurse-submodules -j8 --depth 1 --branch ${TSHOCK_VERSION} https://github.com/Pryaxis/TShock.git /app
WORKDIR /app
RUN nuget restore ./TerrariaServerAPI/ && \
    msbuild ./TerrariaServerAPI/TShock.4.OTAPI.sln /p:Configuration=$BUILD_MODE && \
    cd ./TerrariaServerAPI/TShock.Modifications.Bootstrapper/bin/$BUILD_MODE/ && \
    mono TShock.Modifications.Bootstrapper.exe -in=OTAPI.dll \
      -mod=../../../TShock.Modifications.**/bin/$BUILD_MODE/TShock.Modifications.*.dll \ 
      -o=Output/OTAPI.dll && \
    cd ./../../../../ && \
    msbuild ./TerrariaServerAPI/TerrariaServerAPI/TerrariaServerAPI.csproj \
      /p:Configuration=$BUILD_MODE && \
    nuget restore && \
    xbuild ./TShock.sln /p:Configuration=$BUILD_MODE

# Build Terracord
FROM mono:6.8 AS terracord
LABEL maintainer="Didstopia <support@didstopia.com>"
ENV BUILD_MODE=Release
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    git && \
    nuget update -self
RUN git clone --recurse-submodules -j8 --depth 1 --branch master https://github.com/FragLand/terracord.git /app && \
    cd /app && \
    git checkout d52c708a2413d86e57f67fe2c75f494ba5a3730a
WORKDIR /app
RUN mkdir -p /app/lib
COPY --from=tshock /app/TShockAPI/bin/${BUILD_MODE}/ /app/lib/
RUN nuget restore && \
    msbuild /p:Configuration=${BUILD_MODE},TargetFrameworks=net46 Terracord/Terracord.csproj

FROM mono:6.8
LABEL maintainer="Didstopia <support@didstopia.com>"
ENV BUILD_MODE=Release
ENV CONFIG_PATH=/tshock/worlds
ENV LOG_PATH=/tshock/logs
ENV WORLD_FILENAME=""
ENV TERRACORD_ENABLED=false
ENV TERRACORD_SILENCE_BROADCASTS=true
ENV TERRACORD_SILENCE_CHAT=false
ENV TERRACORD_SILENCE_SAVES=true
ENV TERRACORD_ANNOUNCE_RECONNECT=false
EXPOSE 7777 7878
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    screen \
    procps \
    bash \
    xmlstarlet
WORKDIR /tshock
VOLUME ["/tshock/worlds", "/tshock/logs", "/plugins"]
RUN mkdir -p /tshock/ServerPlugins/ && \
    mkdir -p /tshock/tshock/Terracord
COPY entrypoint.sh /tshock/entrypoint.sh
COPY --from=terracord /app/Terracord/bin/${BUILD_MODE}/net46/ /tshock/
COPY --from=terracord /app/Terracord/bin/${BUILD_MODE}/net46/TShockAPI.dll /tshock/ServerPlugins/
COPY --from=terracord /app/terracord.xml /tshock/tshock/Terracord/
RUN chmod +x /tshock/entrypoint.sh && \
    chmod +x /tshock/TerrariaServer.exe && \
    rm -fr /tshock/TShockAPI.dll
ENTRYPOINT [ "/bin/sh", "entrypoint.sh" ]
