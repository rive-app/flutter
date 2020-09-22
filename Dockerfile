FROM google/dart

RUN apt update && apt-get -y install procps

WORKDIR /app/packages/coop_server_process
ADD . /app

WORKDIR /app/packages/coop_server_process
RUN pub get

WORKDIR /app
RUN dart2native packages/coop_server_process/lib/main.dart -o ./coop_server_process

WORKDIR /app
CMD []
ENTRYPOINT ["./coop_server_process", "--data-folder=./data"]
