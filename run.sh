#!/bin/sh

export COMPOSE_FILE_PATH="${PWD}/target/classes/docker/docker-compose.yml"

if [ -z "${M2_HOME}" ]; then
  export MVN_EXEC="mvn"
else
  export MVN_EXEC="${M2_HOME}/bin/mvn"
fi

start() {
    docker volume create edms-aio-acs-volume
    docker volume create edms-aio-db-volume
    docker volume create edms-aio-ass-volume
    docker compose -f "$COMPOSE_FILE_PATH" up --build -d
}

start_share() {
    docker compose -f "$COMPOSE_FILE_PATH" up --build -d edms-aio-share
}

start_acs() {
    docker compose -f "$COMPOSE_FILE_PATH" up --build -d edms-aio-acs
}

down() {
    if [ -f "$COMPOSE_FILE_PATH" ]; then
        docker compose -f "$COMPOSE_FILE_PATH" down
    fi
}

purge() {
    docker volume rm -f edms-aio-acs-volume
    docker volume rm -f edms-aio-db-volume
    docker volume rm -f edms-aio-ass-volume
}

build() {
    $MVN_EXEC clean package
}

build_share() {
    docker compose -f "$COMPOSE_FILE_PATH" kill edms-aio-share
    yes | docker compose -f "$COMPOSE_FILE_PATH" rm -f edms-aio-share
    $MVN_EXEC clean package -pl edms-aio-share,edms-aio-share-docker
}

build_acs() {
    docker compose -f "$COMPOSE_FILE_PATH" kill edms-aio-acs
    yes | docker compose -f "$COMPOSE_FILE_PATH" rm -f edms-aio-acs
    $MVN_EXEC clean package -pl edms-aio-integration-tests,edms-aio-platform,edms-aio-platform-docker
}

tail() {
    docker compose -f "$COMPOSE_FILE_PATH" logs -f
}

tail_all() {
    docker compose -f "$COMPOSE_FILE_PATH" logs --tail="all"
}

prepare_test() {
    $MVN_EXEC verify -DskipTests=true -pl edms-aio-platform,edms-aio-integration-tests,edms-aio-platform-docker
}

test() {
    $MVN_EXEC verify -pl edms-aio-platform,edms-aio-integration-tests
}

case "$1" in
  build_start)
    down
    build
    start
    tail
    ;;
  build_start_it_supported)
    down
    build
    prepare_test
    start
    tail
    ;;
  start)
    start
    tail
    ;;
  stop)
    down
    ;;
  purge)
    down
    purge
    ;;
  tail)
    tail
    ;;
  reload_share)
    build_share
    start_share
    tail
    ;;
  reload_acs)
    build_acs
    start_acs
    tail
    ;;
  build_test)
    down
    build
    prepare_test
    start
    test
    tail_all
    down
    ;;
  test)
    test
    ;;
  *)
    echo "Usage: $0 {build_start|build_start_it_supported|start|stop|purge|tail|reload_share|reload_acs|build_test|test}"
esac