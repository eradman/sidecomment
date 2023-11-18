date != date "+%y-%m"

all: server_tests/passed client_tests/passed

client_tests/passed: client/* client_tests/*.rb client_tests/*.html
	cat client/common.js client/rest.js client/select.js client/comment.js > cdn/sidecomment.js
	client_tests/run.sh
	date > client_tests/passed

server_tests/passed: *.rb schema/* server_tests/*.rb server_tests/*.sql views/*
	server_tests/run.sh
	date > server_tests/passed

clean:
	rm -f .hmac_secret server_tests/.hmac_secret
	rm -f server_tests/passed client_tests/passed
	rm -f run/* log/*

.PHONY: all clean
