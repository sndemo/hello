USERNAME=sndemo
IMAGE=hello

.build:
	sudo docker build -t ${USERNAME}/${IMAGE}:latest .

.release:
	git pull
	# bump version
	#docker run --rm -v "$PWD":/app treeder/bump patch
	version=`cat VERSION`
	echo "version: $version"

	sudo docker build -t ${USERNAME}/${IMAGE}:latest .

	git add -A
	git commit -m "version $version"
	git tag -a "$version" -m "version $version"
	git push
	git push --tags

	sudo docker tag $USERNAME/$IMAGE:latest $USERNAME/$IMAGE:$version

	# push it
	sudo docker push $USERNAME/$IMAGE:latest
	sudo docker push $USERNAME/$IMAGE:$version
