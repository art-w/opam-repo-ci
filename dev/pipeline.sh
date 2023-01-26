#!/bin/sh

# serve local opam-repository for workers...
if [ "$MODE" = "local" ]; then
  cd /opam-repository
  git daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/ &
fi

cd /app

# wait for the cluster to generate the file
until [ -f /app/capnp-secrets/admin.cap ]
do
     sleep 1
done

USER=opam-repo-ci

# submission.cap is used to submit jobs to the workers
ocluster-admin --connect /app/capnp-secrets/admin.cap remove-client "$USER"
ocluster-admin --connect /app/capnp-secrets/admin.cap add-client "$USER" > /app/capnp-secrets/submission.cap

# give permission to workers
chmod -R a+rw /app/capnp-secrets

ulimit -n 102400

EXE='local'
ARG='--path=/opam-repository --repo=art-w/opam-repository'

if [ "$MODE" = "github" ]; then

  EXE='main'
  ARG="--github-app-id=${GITHUB_APP_ID}"
  ARG="$ARG --github-account-allowlist=${GITHUB_ACCOUNT}"
  ARG="$ARG --github-private-key-file=${GITHUB_PRIVATE_KEY_FILE}"
  ARG="$ARG --github-webhook-secret-file=${GITHUB_WEBHOOK_SECRET_FILE}"

  # public IP to receive GitHub webhooks on port 8080
  ngrok authtoken "$NGROK_AUTH"
  ngrok http 8080 --log=stdout > /tmp/ngrok.log &
  URL=$(tail -F /tmp/ngrok.log | grep -m 1 -o -E 'https://[^ ]*.ngrok.io$')
  WEBHOOK="${URL}/webhooks/github"
  
  # update GitHub webhook url
  SECRET=$(cat "$GITHUB_WEBHOOK_SECRET_FILE")
  JWT=$(dune exec --root=. --display=quiet ./dev/jwt.exe "$GITHUB_APP_ID" "$GITHUB_PRIVATE_KEY_FILE")
  curl \
    -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/app/hook/config \
    -d "{\"url\":\"${WEBHOOK}\",\"secret\":\"${SECRET}\"}"

fi

export PWD=/app
dune build --watch service/$EXE.exe ./web-ui/main.exe &

./dev/frontend.sh &

while :
do

  until [ -f _build/default/service/$EXE.exe ]
  do
    sleep 1
  done

  echo _build/default/service/$EXE.exe $ARG \
    --port=8080 \
    --confirm=none \
    --submission-service=/app/capnp-secrets/submission.cap \
    --capnp-address=tcp:localhost:5001

  _build/default/service/$EXE.exe $ARG \
    --port=8080 \
    --confirm=none \
    --submission-service=/app/capnp-secrets/submission.cap \
    --capnp-address=tcp:127.0.0.1:5001 &
  PID=$!

  echo 'Waiting for changes...'

  inotifywait -q -e CLOSE_WRITE _build/default/service | grep -q local.exe \

  kill "$PID"
  wait "$PID"

  sleep 1
done
