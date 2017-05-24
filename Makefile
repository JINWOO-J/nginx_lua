REPO = dr.yt.com
REPO_HUB = jinwoo
NAME = nginx_lua
VERSION = 1.10.3
DEBUG_BUILD = no
#include ENVAR


.PHONY: all build push test tag_latest release ssh

all: build push_hub

test:
		echo $VERSION

changeconfig:
		@CONTAINER_ID=$(shell docker run -d $(NAME):$(VERSION)) ;\
		 echo "COPY TO [$$CONTAINER_ID]" ;\
		 docker cp "files/." "$$CONTAINER_ID":/ ;\
		 docker exec -it "$$CONTAINER_ID" sh -c "echo `date +%Y-%m-%d:%H:%M:%S` > /.made_day" ;\
		 echo "COMMIT [$$CONTAINER_ID]" ;\
		 docker commit -m "Change config `date`" "$$CONTAINER_ID" $(NAME):$(VERSION) ;\
		 echo "STOP [$$CONTAINER_ID]" ;\
		 docker stop "$$CONTAINER_ID" ;\
		 echo "CLEAN UP [$$CONTAINER_ID]" ;\
		 docker rm "$$CONTAINER_ID"

build:
		docker build --no-cache --rm=true --build-arg NGINX_VERSION=nginx-$(VERSION) -t $(NAME):$(VERSION) --build-arg DEBUG_BUILD=${DEBUG_BUILD} .

push:
		docker tag  $(NAME):$(VERSION) $(REPO)/$(NAME):$(VERSION)
		docker push $(REPO)/$(NAME):$(VERSION)

push_hub:
		docker tag  $(NAME):$(VERSION) $(REPO_HUB)/$(NAME):$(VERSION)
		docker push $(REPO_HUB)/$(NAME):$(VERSION)

tag_latest:
		docker tag  $(REPO)/$(NAME):$(VERSION) $(REPO)/$(NAME):latest
		docker push $(REPO)/$(NAME):latest

build_hub:
		echo "TRIGGER_KEY" ${TRIGGERKEY}
		git add .
		git commit -m "$(NAME):$(VERSION) by Makefile"
		git tag -a "$(VERSION)" -m "$(VERSION) by Makefile"
		git push origin --tags
		curl -H "Content-Type: application/json" --data '{"build": true,"source_type": "Tag", "source_name": "$(VERSION)"}' -X POST https://registry.hub.docker.com/u/jinwoo/${NAME}/trigger/${TRIGGERKEY}/

init:
		git init
		git add .
		git commit -m "first commit"
		git remote add origin git@github.com:JINWOO-J/$(NAME).git
		git push -u origin master

bash:
		docker run -v ${PWD}/test:/test -it --rm $(NAME):$(VERSION) bash
