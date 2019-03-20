CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := openshift-namespace-rbac
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init: 
	helm init --client-only

setup: init
	helm repo add jenkinsxio http://chartmuseum.jenkins-x.io 

build: clean setup
	helm dependency build openshift-namespace-rbac
	helm lint openshift-namespace-rbac

install: clean build
	helm upgrade ${NAME} openshift-namespace-rbac --install

upgrade: clean build
	helm upgrade ${NAME} openshift-namespace-rbac --install

delete:
	helm delete --purge ${NAME}

clean:
	rm -rf openshift-namespace-rbac/charts
	rm -rf openshift-namespace-rbac/${NAME}*.tgz
	rm -rf openshift-namespace-rbac/requirements.lock

release: clean build
ifeq ($(OS),Darwin)
	sed -i "" -e "s/version:.*/version: $(VERSION)/" openshift-namespace-rbac/Chart.yaml

else ifeq ($(OS),Linux)
	sed -i -e "s/version:.*/version: $(VERSION)/" openshift-namespace-rbac/Chart.yaml
else
	exit -1
endif
	helm package openshift-namespace-rbac
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
