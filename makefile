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
	git tag -a "$(version)" -m "version $(VERSION)"
	git push
	git push --tags

	sudo docker tag $(USERNAME)/$(IMAGE):latest $(USERNAME)/$(IMAGE):$(version)

	# push it
	sudo docker push $(USERNAME)/$(IMAGE):latest
	sudo docker push $(USERNAME)/$(IMAGE):$(VERSION)
