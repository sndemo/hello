USERNAME=sndemo
IMAGE=hello
VERSION=$(shell cat VERSION)

.build:
	sudo docker build -t $(USERNAME)/$(IMAGE):latest .

.git-push:
	git add *
	git commit -m $(comment)
	git push origin master
.test:
	echo version: $(VERSION)

.release:
	git pull
	echo "version: $(VERSION)"

	sudo docker build -t $(USERNAME)/$(IMAGE):latest .

	git add -A
	git commit -m "version $(VERSION)"
	git tag -a "$(VERSION)" -m "version $(VERSION)"
	git push origin master
	git push origin master --tags -f

	sudo docker tag $(USERNAME)/$(IMAGE):latest $(USERNAME)/$(IMAGE):$(VERSION)

	# push it
	sudo docker push $(USERNAME)/$(IMAGE):latest
	sudo docker push $(USERNAME)/$(IMAGE):$(VERSION)
