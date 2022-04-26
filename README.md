# opam-ci

Status: **experimental**

This is an [OCurrent][] pipeline that tests submissions to [opam-repository][].

## Hacking locally

The normal pipeline requires an OCluster and a GitHub application. To get started faster, you can run
it without all the integrations with `docker-compose`.

### Create a local clone of `opam-repository`

The normal behavior is to watch for new PRs on GitHub, which requires the creation of a GitHub application (see below).
An alternative is to clone the `opam-repository` locally:

```shell
$ opam clone 'https://github.com/ocaml/opam-repository'
```

The `HEAD` of this local git repo will be tested against the `master` branch, so you should select an interesting PR:

```shell
opam-repository/ $ git fetch origin pull/21253/head:pr21253
opam-repository/ $ git checkout pr21253
opam-repository/ $ git diff master # should not be empty, but not too large either!
```

### Run `opam-repo-ci`

`opam-repo-ci` vendors some dependencies with (nested) git submodules. Make sure that your fork is fully initialized:

```shell
$ opam clone --recurse-submodules 'https://github.com/ocurrent/opam-repo-ci'

# or if already cloned
$ opam submodule update --init --recursive
```

You'll need to indicate where `opam-repository` was forked in `dev/conf.env`:

```shell
$ echo 'OPAM_REPO=/home/me/path/to/opam-repository' > dev/conf.env
```

Finally you can start the opam-repo-ci pipeline, frontend, and its ocluster/workers with `make dev-start`.

- The ocurrent pipeline will be available at http://localhost:8080 and the opam-repo-ci frontend will be at http://localhost:8090
- Any modifications to `opam-repo-ci` will rebuild and restart automatically
- You can trigger a rebuild by resetting the `HEAD` of your `opam-repository` (for example with `git commit --amend --no-edit`)
- To shutdown gracefully all the dockers, use `make dev-stop`

## Testing with the GitHub app

In order to test the behaviour of the GitHub App, you will need to create your own private application on GitHub. It will behave just like production, reacting to new PRs and setting their status updates:

1. [**Create a private GitHub App**](https://github.com/settings/apps/new?name=ORCI-dev&url=https:%2F%2Fidonothaveaurl.com&public=false&webhook_active=true&webhook_url=https:%2F%2Fwillbesetuplater.com&pull_requests=write&statuses=write&repository_hooks=write&events=pull_request) (<- this link will pre-configure the required settings)
2. After creation, note the **App ID: 1562..** number on the top of the page
3. Then scroll to the bottom and ask github to **generate a private key**: save the file in `environments/cb-dev-test.pem`
4. Create a **webhook secret** on your computer : `echo -n mysecret > dev/github.secret` (it should not contain a carriage return `\n` hence the `echo -n`)
5. Install your private GitHub application on your fork of `opam-repository`

In order for github to send webhooks to your computer, you will need a public URL. Create a free account on [**ngrok.com**](https://ngrok.com) and note the **auth token 12m4gI45Vzhblablabla...**

Finally edit your `dev/conf.env` to add all the variables:

```
NGROK_AUTH=12m4gI45Vzhblablabla...
GITHUB_APP_ID=156213...
GITHUB_PRIVATE_KEY_FILE=./dev/orci-dev.pem
GITHUB_WEBHOOK_SECRET_FILE=./dev/github.secret
```

You should also remove the `OPAM_REPO` variable from `dev/conf.env`.


## Manual setup

You can also skip the `docker-compose` setup and run everything yourself.
To test locally you will need:

1. A [personal access token][] from GitHub.
2. A `submission.cap` for an [OCluster][] build cluster.

Run the `opam-repo-ci-local` command
(you might need to increase the limit on the number of open files):

```
ulimit -n 102400
dune exec -- opam-repo-ci-local \
  --confirm harmless \
  --submission-service submission.cap \
  --github-token-file token \
  --capnp-address tcp:127.0.0.1:5001
```

Browse to http://localhost:8080 to see the web UI.
You can either set the confirm threshold (at the bottom of the web page) to allow all builds to start,
or just click on a yellow box and then on the `Start now` button to start one step manually.

The analysis step will detect which packages have been changed.
Then, for each supported platform it will try to install the package.
If that succeeds, it will run the package's tests, and in parallel it will find other packages that
depend on this one and test them too.

### Web UI

The public web front-end is a separate process.
It needs a `.cap` file to connect to the engine.
If you have the file for the real service, you can use that.
If you're testing the engine locally (as shown above), you can use the `./capnp-secrets/opam-repo-ci-admin.cap`
that it writes out.

```
dune exec -- opam-repo-ci-web --backend ./capnp-secrets/opam-repo-ci-admin.cap
```

Then browse to http://localhost:8090/github to see the public UI.

[personal access token]: https://github.com/settings/tokens
[OCurrent]: https://github.com/ocurrent/ocurrent
[OCluster]: https://github.com/ocurrent/ocluster
[opam-repository]: https://github.com/ocaml/opam-repository
