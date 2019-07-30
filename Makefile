install:
	apt-get -y install sudo
	sudo apt-get -y install gnupg2
	sudo apt-get -y install curl

	curl http://download.tarantool.org/tarantool/1.10/gpgkey | sudo apt-key add -

	sudo apt-get -y install lsb-release
	release=`lsb_release -c -s`

	sudo apt-get -y install apt-transport-https

	sudo rm -f /etc/apt/sources.list.d/*tarantool*.list
	echo "deb http://download.tarantool.org/tarantool/1.10/ubuntu/ ${release} main" | sudo tee /etc/apt/sources.list.d/tarantool_1_10.list
	echo "deb-src http://download.tarantool.org/tarantool/1.10/ubuntu/ ${release} main" | sudo tee -a /etc/apt/sources.list.d/tarantool_1_10.list

	sudo apt-get -y update
	sudo apt-get -y install tarantool

build: 
	(cd ./db && tarantoolctl rocks install http)

up:
	(cd ./db && tarantool ../src/server.lua)


