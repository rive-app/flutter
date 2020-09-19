FROM google/dart

RUN apt update && apt-get -y install procps

WORKDIR /app/packages/coop_server_process
ADD . /app

WORKDIR /app/packages/coop_server_process
RUN pub get

WORKDIR /app/packages/process_monitor
RUN pub get

WORKDIR /app/packages
CMD []
ENTRYPOINT ["/usr/bin/dart", "process_monitor/lib/main.dart", "/usr/bin/dart", "coop_server_process/lib/main.dart", "--data-folder=./data"]