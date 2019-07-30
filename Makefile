build:
	tarantoolctl rocks install http

up:
	(cd ./db && tarantool ../src/server.lua)


