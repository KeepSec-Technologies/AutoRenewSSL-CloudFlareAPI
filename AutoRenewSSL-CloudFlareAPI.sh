#!/bin/bash
YEL=$'\e[1;33m' # Yellow
RED=$'\033[0;31m' # Red
NC=$'\033[0m' # No Color
PRPL=$'\033[1;35m' # Purple
GRN=$'\e[1;32m' # Green
BLUE=$'\e[3;49;34m' # Blue

printf "${BLUE}\n"
echo '    ___         __        ____                          __________ __ '
echo '   /   | __  __/ /_____  / __ \___  ____  ___ _      __/ ___/ ___// / '
echo '  / /| |/ / / / __/ __ \/ /_/ / _ \/ __ \/ _ \ | /| / /\__ \\__ \/ /  '
echo ' / ___ / /_/ / /_/ /_/ / _, _/  __/ / / /  __/ |/ |/ /___/ /__/ / /___'
echo '/_/  |_\__,_/\__/\____/_/ |_|\___/_/ /_/\___/|__/|__//____/____/_____/'
printf "\nPowered by KeepSec Technologies Inc.™${NC}\n\n"

if [ `id -u` -ne 0 ]; then
      printf "${RED}\nThis script can only be executed as root\n\n\n${NC}"
      sleep 0.5
      exit
   fi

function installing {
  tput civis
  spinner="⣾⣽⣻⢿⡿⣟⣯⣷"
  while :; do
    for i in $(seq 0 7); do
      printf "${PRPL}${spinner:$i:1}"
      printf "\010${NC}"
      sleep 0.2
    done
  done
}

installing &
SPIN_PID=$!
disown
printf "${PRPL}\nInstalling utilities ➜ ${NC}"

if [ -n "$(command -v apt-get)" ]; then
  add-apt-repository ppa:certbot/certbot &> /dev/null
  apt-get -y install pip python3 certbot &> /dev/null
  pip3 install certbot-nginx &> /dev/null
  pip3 install certbot-apache&> /dev/null
  pip3 install certbot-dns-cloudflare &> /dev/null
elif [ -n "$(command -v yum)" ]; then
  yum -y install epel-release &> /dev/null
  yum -y install python3 certbot &> /dev/null
  pip3 install certbot-nginx &> /dev/null
  pip3 install certbot-apache &> /dev/null
  pip3 install certbot-dns-cloudflare &> /dev/null
fi

kill -9 $SPIN_PID &>/dev/null
tput cnorm
echo ""
echo ""
echo ""

read -p "What is the ${YEL}domain${NC} that you want to deploy a wildcard certificate for : " domain
echo ""
sleep 0.5
read -p "What is your ${YEL}email${NC} that you want to use for updates on your certificate renew state : " email
echo ""
sleep 0.5

function webserver {
read -p "Prefered web server between ${YEL}nginx${NC} and ${YEL}apache${NC} : " websrv
if [[ "${websrv}" != @(nginx|apache) ]]; then
    printf "${RED}Type either nginx or apache in lowercase! Try again\n\n${NC}"
    sleep 0.5
    webserver
fi
}

webserver

echo ""
sleep 0.5
read -p "What is your ${YEL}CloudFlare API Token${NC} : " token
echo -e "\n(If you don't know what that is go to ${GRN}https://developers.cloudflare.com/fundamentals/api/get-started/create-token)${NC}"
sleep 1.5
echo ""
echo -e "Starting Certbot...\n"
sleep 0.5

certbot certonly --agree-tos --email $email --$websrv --preferred-challenges=dns -d *.$domain --server https://acme-v02.api.letsencrypt.org/directory

mkdir /etc/letsencrypt/.certbot/ &> /dev/null
mkdir /etc/letsencrypt/.certbot/.secret/ &> /dev/null
tee -a /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini > /dev/null <<EOT
# Cloudflare API token used by Certbot for all domains on mydomain account
dns_cloudflare_api_token = ${token}
EOT
chmod 600 /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini &> /dev/null

croncmd="root /usr/bin/certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.certbot/.secret/cloudflare.${domain}.ini --preferred-challenges dns -d *.${domain} --force-renewal >> /var/log/certbot-cloudflare-api.log"
cronjob="0 0 2 * * $croncmd"

printf "$cronjob\n" > /etc/cron.d/$domain-wild-SSL

printf "${GRN}We're done!\n\n${NC}"

exit
