#!/data/data/com.termux/files/usr/bin/env bash

RED='\033[0;31m'
BLUE='\033[1;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

ipLocal=$(ifconfig 2>/dev/null| grep -w inet | grep -v 127.0.0.1 | awk '{print $2}')
container="nextcloudContainer"
dataDir="$(pwd)/$container"
image="nextcloud"
port=2080

trap "pkill apache2" TERM EXIT

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

UdockerRun()
{
	echo -------------------------
	echo -e "🖥️${BLUE}Starting container...${NC}"
	echo -e "${RED}Please be patient, This process will take a few minutes.${NC}"
	udocker run -p "$port:80" \
				-v "$dataDir:/var/www/html" \
				"$container" > $(pwd)/nextcloud.log 2>&1 &
}

ByeBye(){
	echo -------------------------
	echo -e "🚪${BLUE}Exiting...${NC}"
	exit
}

Status()
{
	nextcloudVersion=$(udocker inspect $container|grep NEXTCLOUD_VERSION|awk -F= 'NR==1 {print $2}'|tr -d '\"')
	storage="$(df -h |grep fuse|awk '{print $3}')/$(df -h |grep fuse|awk '{print $2}')"
	echo -------------------------
	echo Status
	echo -------------------------
	echo URL: $ipLocal:2080
	echo Storage: $storage Used
	echo Nextcloud version: $nextcloudVersion
	echo Create by: Lira
	echo -------------------------
	echo Press Enter to exit
	read
}

Backup()
{
	echo -------------------------
	echo -e "📦${BLUE}Creating backup...${NC}"
	now=$(pwd)
	cd $dataDir/
	tar cf $now/backup.tar ./data >/dev/null 2>&1 & Loading
	cd $now
	echo -e "✅${YELLOW}Backup created successfully in your current folder.${NC}"
}

Debloat()
{
	list=(apps/activity/ apps/comments/ apps/dashboard/ \
	      apps/photos/ apps/profile/ apps/weather_status/ \
	      apps/nextcloud_announcements/ apps/files_sharing/ \
	      apps/support/ apps/sharebymail/ apps/notifications/ \
	      apps/updatenotification/ apps/systemtags/ apps/recommendations/ \
	      apps/survey_client/ apps/contactsinteraction/ apps/firstrunwizard/ \
	      apps/federation/ apps/bruteforcesettings/ apps/suspicious_login/ \
	      apps/password_policy/ apps/oauth2/ apps/twofactor_totp/ \ 
	      apps/twofactor_backupcodes/ apps/twofactor_nextcloud_notification/ core/skeleton/)

	for char in ${list[@]}
	do
		rm $dataDir/$char -r >/dev/null 2>&1
	done
}

Run()
{
	case "$1" in
		1) UdockerRun;;
		2) Status;;
		3) Debloat;;
		4) Backup;;
		5) ByeBye;;
		*) 
			echo -------------------------
			echo 'Invalid number'
		;;
		esac
}

Menu()
{
	echo -------------------------
	echo Menu
	echo -------------------------
	echo '1) - Start'
	echo '2) - Status'
	echo '3) - Debloat'
	echo '4) - Backup'
	echo '5) - Exit'
	echo -------------------------
	echo Select a number
	read var
	Run $var
}

main()
{
	clear

	InstallUdocker
	UdockerCreate "$container" "$image"

	mkdir $dataDir >/dev/null 2>&1
	while true; do
		Menu
	done
}
main
