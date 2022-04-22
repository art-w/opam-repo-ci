#!/bin/sh

# wait for the pipeline to generate the file
until [ -f /app/dev/capnp-secrets/opam-repo-ci-admin.cap ]
do
  sleep 1
done

export PWD=/app
dune build --watch ./web-ui/main.exe &

while :
do
  until [ -f _build/default/web-ui/main.exe ]
  do
    echo 'Waiting for build...'
    sleep 1
  done

  _build/default/web-ui/main.exe --backend /app/dev/capnp-secrets/opam-repo-ci-admin.cap &

  echo 'Waiting for changes...'

  inotifywait -q -e CLOSE_WRITE _build/default/web-ui | grep -q main.exe \
  && (pkill -f '^_build/default/web-ui/main.exe' || echo 'Not running?') \
  && sleep 1 \
  && (pkill -f '^_build/default/web-ui/main.exe' || echo 'Not running?') \
  && sleep 1 \
  && (pkill -f '^_build/default/web-ui/main.exe' || echo 'Not running?') \
  && sleep 1
done
