docker run -d \
	--rm \
	--name myblog \
	-p 4000:4000 \
	--mount type=bind,source=$(pwd),target=/myblog \
	myblog:latest
