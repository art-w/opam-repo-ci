CONTEXT := ci.ocamllabs.io

all:
	dune build ./service/main.exe ./client/main.exe ./web-ui/main.exe ./service/local.exe @runtest

deploy-stack:
	docker --context $(CONTEXT) stack deploy --prune -c stack.yml opam-repo-ci

.PHONY: dev-start
dev-start:
	rm -Rf dev/capnp-secrets
	docker-compose \
		--project-name=opam-repo-ci \
		--file=./dev/docker-compose.yml \
		--env-file=./dev/conf.env \
		up \
		--remove-orphans \
		--build

.PHONY: dev-stop
dev-stop:
	docker-compose \
		--project-name=opam-repo-ci \
		--file=./dev/docker-compose.yml \
		--env-file=./dev/conf.env \
		down
