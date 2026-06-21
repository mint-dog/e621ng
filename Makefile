DOCKER_IMAGE ?= e621

.PHONY: build-dev build-prod

build-dev:
	docker compose build --no-cache e621

build-prod:
	docker build --no-cache \
	  --build-arg INCLUDE_DEV=false \
	  --build-arg INSTALL_CRON=true \
	  -t $(DOCKER_IMAGE):prod .
