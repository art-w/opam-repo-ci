#!/bin/sh

# serve local opam-repository for workers...
if [ -d /opam-repository ]; then
  cd /opam-repository
  git daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/ &
fi

cd /app

# wait for the cluster to generate the file
until [ -f /app/dev/capnp-secrets/admin.cap ]
do
     sleep 1
done

USER=opam-repo-ci

# submission.cap is used to submit jobs to the workers
ocluster-admin --connect /app/dev/capnp-secrets/admin.cap remove-client "$USER"
ocluster-admin --connect /app/dev/capnp-secrets/admin.cap add-client "$USER" > /app/dev/capnp-secrets/submission.cap

# give permission to workers
chmod -R a+rw /app/dev/capnp-secrets

ulimit -n 102400

dune build --watch service/local.exe &

while :
do

  until [ -f _build/default/service/local.exe ]
  do
    echo 'Waiting for build...'
    sleep 1
  done

  _build/default/service/local.exe \
    --port=8080 \
    --confirm=none \
    --submission-service=/app/dev/capnp-secrets/submission.cap \
    --path=/opam-repository \
    --capnp-address=tcp:pipeline:5001 \
    --repo=local/opam-repository &

  echo 'Waiting for changes...'

  inotifywait -q -e CLOSE_WRITE _build/default/service | grep -q local.exe \
  && (pkill -f '^_build/default/service/local.exe' || echo 'Not running?') \
  && sleep 1
done
