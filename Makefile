RUNTIME   := nodejs12.x
STAGES    := build test
TERRAFORM := latest
BUILD     := $(shell git describe --tags --always)
CLEANS    := $(foreach STAGE,$(STAGES),clean@$(STAGE))
IMAGES    := $(foreach STAGE,$(STAGES),image@$(STAGE))
SHELLS    := $(foreach STAGE,$(STAGES),shell@$(STAGE))

.PHONY: default clean $(CLEANS) $(IMAGES) $(SHELLS)

default: package-lock.json package.zip test

.docker:
	mkdir -p $@

.docker/$(BUILD)-build: package.json
.docker/$(BUILD)-test:  .docker/$(BUILD)-build
.docker/$(BUILD)-%:   | .docker
	docker build \
	--build-arg RUNTIME=$(RUNTIME) \
	--build-arg TERRAFORM=$(TERRAFORM) \
	--iidfile $@ \
	--tag amancevice/slackbot-slash-command:$(BUILD)-$* \
	--target $* .

package-lock.json package.zip: .docker/$(BUILD)-build
	docker run --rm --entrypoint cat $(shell cat $<) $@ > $@

clean: $(CLEANS)

clobber: | .docker
	-awk {print} .docker/* 2> /dev/null | uniq | xargs docker image rm --force
	-rm -rf .docker node_modules

test: .docker/$(BUILD)-test

$(CLEANS): clean@%:
	-rm -rf .docker/$(BUILD)-$*

$(IMAGES): image@%: .docker/$(BUILD)-%

$(SHELLS): shell@%: .docker/$(BUILD)-%
	docker run --rm -it --entrypoint sh $(shell cat $<)