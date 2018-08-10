APP.NAME=hello
APP.NAMESPACE=demo-hello
APP.MS.NAME=hello
APP.MS.VERSION=$(shell cat version.txt)
APP.MS.IMAGE=sndemo/hello
RELEASE=APP.NAME+'.'+APP.MS.NAME

# Generate helm values.yaml contents
define VALUES 
app:
  name: $(APP.NAME) 
  namespace: $(APP.NAMESPACE)
  ms:
    name: $(APP.MS.NAME) 
    version: $(APP.MS.VERSION) 
    replicas: 2 
    image: '$(APP.MS.IMAGE)'
endef

export VALUES

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

	git add * 
	git commit -m "version $(APP.MS.VERSION)"
	git tag -a "$(APP.MS.VERSION)" -m "version $(APP.MS.VERSION)" -f
	git push origin master
	git push origin master --tags -f

.release-docker-push:
	sudo login -u sndemo
	sudo docker tag $(APP.MS.IMAGE):latest $(APP.MS.IMAGE):$(APP.MS.VERSION)

	# push it
	sudo docker push $(APP.MS.IMAGE):latest
	sudo docker push $(APP.MS.IMAGE):$(APP.MS.VERSION)

.release-deploy:
	kubectl create namespace $(APP.MS.NAMESPACE)
	helm upgrade -i RELEASE ./helm

.release: .echo .update-helm-values .release-build .release-docker-push .release-deploy
