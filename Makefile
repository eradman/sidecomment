date != date "+%y-%m"

all: cdn/sidecomment.js server_tests/passed client_tests/passed

cdn/sidecomment.js: sidecomment.js
	cp sidecomment.js cdn/sidecomment.js

client_tests/passed: client_tests/*.rb client_tests/*.html
	client_tests/run.sh
	date > client_tests/passed

server_tests/passed: *.rb schema/* server_tests/*.rb server_tests/*.sql views/*
	server_tests/run.sh
	date > server_tests/passed

lint:
	rubocop33

format:
	npx prettier --write '*.js' 'public/*.js'

clean:
	rm -f .hmac_secret server_tests/.hmac_secret
	rm -f .local_sitecode server_tests/.local_sitecode
	rm -f server_tests/passed client_tests/passed
	rm -f run/* log/*

.PHONY: all clean lint
