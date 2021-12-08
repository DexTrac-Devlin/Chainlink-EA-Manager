#!/bin/bash


########################################################
#                Formatting Variables                  #
########################################################
b=$(tput bold)
n=$(tput sgr0)
un=$(tput smul)
nun=$(tput rmul)

########################################################
#                      Variables                       #
########################################################
VERSION="0.0.1"

# Grab API keys from flat file
source api_keys

# $1 --> option (--deploy)
# $2 --> external adapter name (--coingekco)
# $3 --> specific version for external adapter (0.1.4)

########################################################
#                 INITIALIZE FUNCTION                  #
########################################################
Initialize() {
# Initializes a new Docker environment
  echo "${b}Initializing new Docker environment...${n}"

  # Intall Docker if not already installed
  if [ $(dpkg-query -W -f='${Status}' docker 2>/dev/null | grep -c "Docker already installed") -eq 0 ];
  then
    # Check if running as root
    if [ "$EUID" -ne 0 ]
      then echo "${b} Run as elevated user (sudo)${n}"
      exit
    fi
    read -p "${b} Enter your non-root username:${n} " USERNAME
    aptInstall () {
      echo "${b}Updating apt & Installing Docker-CE${n}"
      apt-get -y update >>/dev/null 2>&1
      apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common >>/dev/null 2>&1
      curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - >>/dev/null 2>&1
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" >>/dev/null 2>&1
      apt-get -y update >>/dev/null 2>&1
      apt-get -y install docker-ce >>/dev/null 2>&1
      groupadd docker >>/dev/null 2>&1
      sudo usermod -aG docker $USERNAME >>/dev/null 2>&1
    }
    yumInstall (){
      echo " Updating yum"
      echo " Installing dependencies & Docker-CE"
      sudo yum remove docker* >>/dev/null 2>&1
      sudo yum -y update >>/dev/null 2>&1
      sudo yum -y remove docker* >>/dev/null 2>&1
      sudo yum -y install yum-utils >>/dev/null 2>&1
      sudo yum-config-manager \ --add-repo \ https://download.docker.com/linux/centos/docker-ce.repo  >>/dev/null 2>&1
      sudo yum -y install docker-ce docker-ce-cli containerd.io >>/dev/null 2>&1
      sudo systemctl start docker >>/dev/null 2>&1
      groupadd docker >>/dev/null 2>&1
      sudo usermod -aG docker $USERNAME >>/dev/null 2>&1
      sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >>/dev/null 2>&1
      sudo chmod +x /usr/local/bin/docker-compose
      docker-compose --version
      sudo dnf install git -y
    }
    apt=`command -v apt-get`
    yum=`command -v yum`

    if [ -n "$apt" ]; then
      echo "apt detected"
      aptInstall
    elif [ -n "$yum" ]; then
      echo "yum detected"
      yumInstall
    else
      echo "Err: apt or yum not detected.";
      exit 1;
    fi
  fi

  # create docker network
  echo "${b}Creating Docker network...${n}"
  docker network create \
  --driver=bridge \
  --subnet=192.168.1.0/16 \
  --gateway=192.168.0.1 \
  eas-net

  # create directory to use for redis volume
if [ ! -d /home/mlzboy/b2c2/shared/db ]; then
  echo "${b}Creating Redis container...${n}"
  mkdir ~/.redis;
fi


  # deploy redis container
  echo "${b}Redis volume located at ~/.redis${n}"
  docker run \
  --name redis-cache \
  --restart=unless-stopped \
  --net eas-net \
  --ip=192.168.1.1 \
  -p 6379:6379 \
  -v ~/.redis:/data \
  -d redis redis-server

  # Provide Redis container information
  echo ""
  echo "${b}Redis container info:${n}"
  echo "cnt8rName: redis-cache"
  echo "IPaddress: 192.168.1.1"
  echo "listnPort: 6379"
}

########################################################
#                    DEPLOY FUNCTION                   #
########################################################
Deploy() {
# Deploy new EA
echo "${b}Deploying $1:$2 external adapter...${n}"
echo "test command with variables:"
bash standardEAs/$1-redis.sh $2
}

########################################################
#                  VERSION FUNCTION                    #
########################################################
Version() {
# Print Version
echo "eaManager version: ${b}$VERSION${n}"
}

########################################################
#                    HELP FUNCTION                     #
########################################################
Help() {
  # Display Help
  echo "This script helps you deploy, manage, and upgrade your Chainlink external adapters."
  echo
  echo "Usage:  ${b}eaManager option EA_NAME EA_VERSION${n}"
  echo ""
  echo "options:"
  echo ""
  echo "-i        Initializes a generic EA environment."
  echo "${b}            Creates Docker network, deploys redis container,${n}"
  echo "${b}            use this if you want a quick turnkey deployment.${n}"
  echo ""
  echo "-d        Deploys new external adapter."
  echo "${b}            ex: eaManager -d coingecko 1.0.4${n}"
  echo ""
  echo "-u        Upgrades external adapter."
  echo "${b}            ex: eaManager -u coingecko 1.0.4${n}"
  echo ""
  echo "-v        Print script version and exit."
  echo ""
  echo "-h        Print this Help function and exit."
  echo
}

########################################################
#                        MAIN                          #
########################################################
while getopts ":id:u:vh" option; do
   case ${option} in
      i) # deploy new external adapter
         Initialize
         exit
         ;;
      d) # deploy new external adapter
         shift
         Deploy "$@"
         exit
         ;;
      u) # upgrade existing external adapter
         Upgrade
         exit
         ;;
      v) # Print Version
         Version
         exit
         ;;
      h) # Display Help
         Help
         exit
         ;;
      \?) # Invalid Option
         echo "Invalid option: $OPTARG" 1>&2
         exit 1
         ;;
      :) # Invalid Option
         echo "Invalid option: $OPTARG requires an argument" 1>&2
         echo ""
         echo "Please specify the external adapter name" 1>&2
         echo "ex: ${b}eaManager -$OPTARG coingecko${n}" 1>&2
         exit 1
         ;;
   esac
done


