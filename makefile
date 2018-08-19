TENANT=t1
APP.NAME=hello
APP.NAMESPACE=$(APP.NAME)-$(TENANT)
APP.MS.NAME=hello
APP.MS.VERSION=$(shell cat version.txt)
APP.MS.IMAGE=sndemo/$(APP.MS.NAME)
RELEASE=$(APP.NAME).$(APP.MS.NAME)
NAMESPACE_STATUS=$(shell kubectl get namespace $(APP.NAMESPACE) -o=jsonpath='{.status.phase}' 2>>/dev/null)

# Generate helm values.yaml contents
define VALUES 
app:
  name: $(APP.NAME) 
  namespace: $(APP.NAMESPACE)
  ms:
    name: $(APP.MS.NAME) 
    version: '$(APP.MS.VERSION)'
    replicas: 2 
    image: '$(APP.MS.IMAGE)'
endef

export VALUES


ifneq ($(NAMESPACE_STATUS),Active)
	CREATE_NAMESPACE=kubectl create namespace $(APP.NAMESPACE)
endif

.echo:
	echo "APP.NAME=$(APP.NAME)"
	echo "APP.NAMESPACE=$(APP.NAMESPACE)"
	echo "APP.MS.NAME=$(APP.MS.NAME)"
	echo "APP.MS.VERSION=$(APP.MS.VERSION)"
	echo "APP.MS.IMAGE=$(APP.MS.IMAGE)"
	echo "RELEASE=$(RELEASE)"

.update-helm-values:
	@echo "$$VALUES" > helm/values.yaml
	

.release-build:
	git pull
	
	echo "version: $(APP.MS.VERSION)"
	#replace version in version file if APP.MS.VERSION variable is passed in  make commad e.g. 'make .release APP.MS.VERSION=1.0.2'
	sed -i -e 's/.*$$/$(APP.MS.VERSION)/g' version.txt 

	sudo docker build -t $(APP.MS.IMAGE):latest .

	git add -A 
	git commit -m "version $(APP.MS.VERSION)"
	git tag -a "$(APP.MS.VERSION)" -m "version $(APP.MS.VERSION)" -f
	git push origin master
	git push origin master --tags -f

.release-docker-push:
	sudo docker login -u sndemo
	sudo docker tag $(APP.MS.IMAGE):latest $(APP.MS.IMAGE):$(APP.MS.VERSION)

	# push it
	sudo docker push $(APP.MS.IMAGE):latest
	sudo docker push $(APP.MS.IMAGE):$(APP.MS.VERSION)

.release-deploy:
	$(CREATE_NAMESPACE)

	# this is workaround as manual sidecar inject of istio does not support helm
	$(RM) helm/templates/*
	cp helm/tmpls/deployment.yaml helm/templates/
	helm install --debug --dry-run --name=test ./helm | sed -n '/---/,$$p' > helm/templates/temp.yaml
	$(RM) helm/templates/deployment.yaml
	istioctl kube-inject -f helm/templates/temp.yaml > helm/templates/deployment.yaml
	$(RM) helm/templates/temp.yaml

	helm upgrade -i $(RELEASE) ./helm --namespace $(APP.NAMESPACE)

.release: .echo .update-helm-values .release-build .release-docker-push .release-deploy
