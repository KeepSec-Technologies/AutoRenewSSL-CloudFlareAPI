#!/bin/bash
YEL=$'\e[1;33m'     # Yellow
RED=$'\033[0;31m'   # Red
NC=$'\033[0m'       # No Color
PRPL=$'\033[1;35m'  # Purple
GRN=$'\e[1;32m'     # Green
BLUE=$'\e[3;49;34m' # Blue

#script logo with copyrights
printf "${BLUE}\n"
echo '    ___         __        ____                          __________ __ '
echo '   /   | __  __/ /_____  / __ \___  ____  ___ _      __/ ___/ ___// / '
echo '  / /| |/ / / / __/ __ \/ /_/ / _ \/ __ \/ _ \ | /| / /\__ \\__ \/ /  '
echo ' / ___ / /_/ / /_/ /_/ / _, _/  __/ / / /  __/ |/ |/ /___/ /__/ / /___'
echo '/_/  |_\__,_/\__/\____/_/ |_|\___/_/ /_/\___/|__/|__//____/____/_____/'
printf "\nPowered by KeepSec Technologies Inc.™${NC}\n\n"

#check if root or not
if [ $(id -u) -ne 0 ]; then
  printf "${RED}\nThis script can only be executed as root\n\n\n${NC}"
  sleep 0.5
  exit
fi

#function for the installing wheel
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

#executes function above
installing &
SPIN_PID=$!
disown
printf "${PRPL}\nInstalling utilities ➜ ${NC}"

#checks package manager and then install all the necessary utilities with your right package manager
if [ -n "$(command -v apt-get)" ]; then
  add-apt-repository ppa:certbot/certbot &>/dev/null
  apt-get -y install pip python3.9 &>/dev/null
  apt remove -y certbot &>/dev/null
  snap remove certbot &>/dev/null
  python3 -m venv /opt/certbot/ &>/dev/null
  yes | /opt/certbot/bin/pip install --upgrade pip &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-nginx &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-apache &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-dns-cloudflare &>/dev/null
  ln -s /opt/certbot/bin/certbot /usr/bin/certbot &>/dev/null
elif [ -n "$(command -v dnf)" ]; then
  dnf -y install epel-release &>/dev/null
  dnf -y install python39 &>/dev/null
  dnf -y remove certbot &>/dev/null
  snap remove certbot &>/dev/null
  python3 -m venv /opt/certbot/ &>/dev/null
  yes | /opt/certbot/bin/pip install --upgrade pip &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-nginx &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-apache &>/dev/null
  yes | /opt/certbot/bin/pip3 install certbot-dns-cloudflare &>/dev/null
  ln -s /opt/certbot/bin/certbot /usr/bin/certbot &>/dev/null
fi

#kills spinning wheel
kill -9 $SPIN_PID &>/dev/null
tput cnorm
echo ""
echo ""

# Check for successful package installation
if ! command -v certbot &>/dev/null; then
  printf "${RED}\nCertbot installation failed! Please check the logs.${NC}\n"
  sleep 0.5
  exit 1
fi

# function to get your domain
function certbot_domain {
  echo ""
  read -p "What is the ${YEL}domain${NC} that you want to deploy a wildcard certificate for: " domain
  domain=$(echo $domain | tr '[:upper:]' '[:lower:]')
  # check if the domain is valid format
  if [[ ! "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf "${RED}\nInvalid domain format! Please try again.\n${NC}"
    sleep 0.5
    certbot_domain
  fi
  sleep 0.5
}

# function to get your email
function certbot_email {
  echo ""
  read -p "What is your ${YEL}email${NC} address for certbot: " email
  email=$(echo $email | tr '[:upper:]' '[:lower:]')
  # check if the email is valid format
  if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    printf "${RED}\nInvalid email format! Please try again.\n${NC}"
    sleep 0.5
    certbot_email
  fi
  sleep 0.5
}

# function to make your web server only nginx or apache
function webserver {
  echo ""
  read -p "What is used between ${YEL}nginx${NC} and ${YEL}apache${NC}: " websrv
  # make it lower case
  websrv=$(echo $websrv | tr '[:upper:]' '[:lower:]')
  if [[ "${websrv}" != @(nginx|apache) ]]; then
    printf "${RED}\nPlease type either nginx or apache! Try again\n${NC}"
    sleep 0.5
    webserver
  fi

  # adjust between 'apache' or 'nginx' reload commands
  if [[ "${websrv}" = "apache" ]]; then
    reloadcmd="apachectl -k graceful"
  elif [[ "${websrv}" = "nginx" ]]; then
    reloadcmd="nginx -s reload"
  fi
  sleep 0.5
}

# function to get your CloudFlare API Token
function cloudflare_token {
  echo ""
  echo -e "(If you don't know what that is, go to ${BLUE}https://developers.cloudflare.com/fundamentals/api/get-started/create-token${NC})"
  read -p "What is your ${YEL}CloudFlare API Token${NC}: " token

  # Verify the CloudFlare API Token
  if ! curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer ${token}" | grep -q '"success":true'; then
    printf "${RED}\nInvalid CloudFlare API Token! Please try again.\n${NC}"
    sleep 0.5
    cloudflare_token
  else 
    printf "${GRN}\nCloudFlare API Token verified successfully!\n${NC}"
    sleep 0.5
  fi

}

certbot_domain

certbot_email

webserver

cloudflare_token

echo -e "\nStarting Certbot...\n"
sleep 0.5

# stores api token to auto renew for future occasions
mkdir -p /etc/letsencrypt/.certbot/.secret/ &>/dev/null
tee /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini >/dev/null <<EOT
# Cloudflare API token used by Certbot for $domain wildcard SSL renewal
dns_cloudflare_api_token = ${token}
EOT
chmod 600 /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini &>/dev/null
chown root:root /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini &>/dev/null

# makes cronjob to execute certbot every day
cronjob="0 0 * * root /bin/bash -c '/usr/bin/certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.certbot/.secret/cloudflare.${domain}.ini --preferred-challenges dns -d \"*.${domain}\" --non-interactive --deploy-hook \"$reloadcmd\" >> /var/log/certbot-cloudflare-api.log 2>&1'"

# execute the first renewal
certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.certbot/.secret/cloudflare.${domain}.ini --preferred-challenges dns -d "*.${domain}" --cert-name "${domain}" --non-interactive --agree-tos --email ${email} --force-renewal > /var/log/certbot-cloudflare-api.log
$reloadcmd

# puts the cronjob in /etc/cron.d/
printf "$cronjob\n\n" > /etc/cron.d/$domain-wild-SSL

# bye bye message :)
printf "${GRN}\nWe're done!\n\n${NC}"

exit
