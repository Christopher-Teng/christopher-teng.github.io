docker run -d \
	--rm \
	--name myblog \
	-u "$(id -u):$(id -g)" \
	-p 4000:4000 \
	--mount type=bind,source=$PWD,target=/myblog \
	myblog:latest
