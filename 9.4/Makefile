base:
	@docker build -t goodrainapps/postgresql:build -f Dockerfile.base .

build:
	@docker run -it -v ${PWD}/tmp:/tmp -v ${PWD}/builded:/usr/local/pgsql/ goodrainapps/postgresql:build

clean:
	rm -rf tmp/* builded/*

release:
	@docker build  -t goodrainapps/postgresql:$(shell cat VERSION) .
