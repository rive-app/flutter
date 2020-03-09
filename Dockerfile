FROM google/dart

WORKDIR /app/server_process
ADD . /app
RUN pub get

CMD []
ENTRYPOINT ["/usr/bin/dart", "lib/main.dart", "--data-folder=./data", "-p"]