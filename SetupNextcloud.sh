#!/data/data/com.termux/files/usr/bin/bash

RED='\033[0;31m'
BLUE='\033[1;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

ipLocal=$(ifconfig 2>/dev/null| grep inet | grep -v 127.0.0.1 | awk '{print $2}')
conteiner="nextcloudConteiner"
image="nextcloud"
port=2080

Loading()
{
	  local pid=$!
	  local spin='-\|/'
	  local i=0
	  while kill -0 $pid 2>/dev/null; do
	      i=$(( (i+1) %4 ))
	      printf "\r[%s]" "${spin:$i:1}"
	      sleep 0.1
	  done
	  printf "\r"
}

UdockerCreate()
{
	if ! udocker ps|grep "$1" >/dev/null 2>&1; then
		UdockerPull $2

		echo -e "🧰${BLUE}Creating the Nextcloud container...${NC}"
		udocker create --name="$1" "$2" >/dev/null 2>&1 & Loading
		echo -e "✅${YELLOW}Container was created successfully.${NC}"
	  fi
}

InstallUdocker()
{
	if ! command -v udocker >/dev/null 2>&1; then
		echo -e "📦${BLUE}Synchronizing the repository...${NC}"
		pkg update >/dev/null 2>&1 & Loading

		echo -e "💾${BLUE}Installing udocker...${NC}"
		pkg install udocker -y >/dev/null 2>&1 & Loading
		echo -e "✅${YELLOW}Installed successfully.${NC}"
	fi
}

UdockerPull()
{
	 if  ! udocker images| grep "$1" >/dev/null 2>&1; then
		echo -e "📲${BLUE}Downloading the $1 image...${NC}"
		udocker pull "$1" >/dev/null 2>&1 & Loading
		echo -e "✅${YELLOW}Image downloaded successfully.${NC}"
	fi
}

main()
{
	clear

	InstallUdocker
	UdockerCreate "$conteiner" "$image"

	dataDir="$(pwd)/$conteiner"
	mkdir $dataDir >/dev/null 2>&1

	echo -e "✅${YELLOW}Container started successfully.${NC}"

	echo "-------------------------------------------"
	echo -e "${BLUE}Nextcloud server URL${NC} $ipLocal:$port"
	echo -e "${RED}Press Ctrl-C to quit.${NC}"

	setsid udocker run -p "$port:80" \
				-v "$dataDir:/var/www/html" \
				"$conteiner" >$(pwd)/nextcloud.log 2>&1 &
	trap "pkill apache2" SIGINT
	sleep infinity
}
main
