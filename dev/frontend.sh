#!/bin/sh

# wait for the pipeline to generate the file
until [ -f /app/capnp-secrets/opam-repo-ci-admin.cap ]
do
  sleep 1
done

while :
do
  until [ -f _build/default/web-ui/main.exe ]
  do
    sleep 1
  done

  _build/default/web-ui/main.exe --backend /app/capnp-secrets/opam-repo-ci-admin.cap &
  PID=$!

  echo 'Waiting for changes...'

  inotifywait -q -e CLOSE_WRITE _build/default/web-ui | grep -q main.exe

  kill "$PID"
  wait "$PID"

  sleep 1
done
