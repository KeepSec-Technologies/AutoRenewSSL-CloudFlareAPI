#!/bin/bash
YEL=$'\e[1;33m' # Yellow
RED=$'\033[0;31m' # Red
NC=$'\033[0m' # No Color
PRPL=$'\033[1;35m' # Purple
GRN=$'\e[1;32m' # Green
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
if [ `id -u` -ne 0 ]; then
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
  add-apt-repository ppa:certbot/certbot &> /dev/null
  apt-get -y install pip python3.9 &> /dev/null
  apt remove -y certbot &> /dev/null
  snap remove certbot &> /dev/null
  python3 -m venv /opt/certbot/ &> /dev/null
  yes | /opt/certbot/bin/pip install --upgrade pip &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-nginx &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-apache &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-dns-cloudflare &> /dev/null
  ln -s /opt/certbot/bin/certbot /usr/bin/certbot &> /dev/null
elif [ -n "$(command -v yum)" ]; then
  yum -y install epel-release &> /dev/null
  yum -y install python39 &> /dev/null
  yum -y remove certbot &> /dev/null
  snap remove certbot &> /dev/null
  python3 -m venv /opt/certbot/ &> /dev/null
  yes | /opt/certbot/bin/pip install --upgrade pip &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-nginx &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-apache &> /dev/null
  yes | /opt/certbot/bin/pip3 install certbot-dns-cloudflare &> /dev/null
  ln -s /opt/certbot/bin/certbot /usr/bin/certbot &> /dev/null
fi

#kills spinning wheel
kill -9 $SPIN_PID &>/dev/null
tput cnorm
echo ""
echo ""
echo ""

#series of questions to get your parameters
read -p "What is the ${YEL}domain${NC} that you want to deploy a wildcard certificate for : " domain
echo ""
sleep 0.5
read -p "What is your ${YEL}email${NC} that you want to use for updates on your certificate renew state : " email
echo ""
sleep 0.5

#function to make your web server only nginx or apache
function webserver {
read -p "Prefered web server between ${YEL}nginx${NC} and ${YEL}apache${NC} : " websrv
if [[ "${websrv}" != @(nginx|apache) ]]; then
    printf "${RED}Type either nginx or apache in lowercase! Try again\n\n${NC}"
    sleep 0.5
    webserver
fi
#adjust between 'apache2' or 'httpd' between os if you choose apache for the restart command at the end
if [[ "${websrv}" = "apache" ]]; then
      if [ -n "$(command -v apt-get)" ]; then
        websrvDef="apache2"
        restartcmd="/etc/init.d/$websrvDef restart"
      elif [ -n "$(command -v yum)" ]; then
        websrvDef="httpd"
        restartcmd="systemctl restart $websrvDef"
      fi
elif [[ "${websrv}" = "nginx" ]]; then
    websrvDef="nginx"
      if [ -n "$(command -v apt-get)" ]; then
        restartcmd="/etc/init.d/$websrvDef restart"
      elif [ -n "$(command -v yum)" ]; then
        restartcmd="systemctl restart $websrvDef"
      fi
fi
}

webserver

sleep 0.5
#asks for CloudFlare API Token
echo -e "\n(If you don't know what that is go to ${GRN}https://developers.cloudflare.com/fundamentals/api/get-started/create-token${NC})"
read -p "What is your ${YEL}CloudFlare API Token${NC} : " token
sleep 1.5
echo -e "\nStarting Certbot...\n"
sleep 0.5

#stores api token to auto renew for future occasions
mkdir -p /etc/letsencrypt/.certbot/.secret/ &> /dev/null
tee /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini > /dev/null <<EOT
# Cloudflare API token used by Certbot for all domains on mydomain account
dns_cloudflare_api_token = ${token}
EOT
chmod 600 /etc/letsencrypt/.certbot/.secret/cloudflare.$domain.ini &> /dev/null

#put rename script in /etc/letsencrypt/.certbot/rename-LE-dir.sh
cat >"/etc/letsencrypt/.certbot/rename-LE-dir.sh" <<EOF
#!/bin/bash

# Define the base directory
base_dir="/etc/letsencrypt/live"

# List, sort, and get the highest numbered directory
highest_dir=$(ls -dv ${base_dir}/${1}-* 2>/dev/null | tail -n 1)

# Check if the highest numbered directory exists
if [ -n "$highest_dir" ]; then
    # Rename the highest numbered directory
    mv "$highest_dir" "${base_dir}/${1}"
    echo "Renamed $highest_dir to ${base_dir}/vpsmini.keepsec.cloud"
else
    echo "No directories found to rename."
fi
EOF

#makes cronjob to execute certbot every week (lets encrypt needs to be renewed every 3 months), also outputs execution in /var/log/certbot-cloudflare-api.log when it runs
dqt='"'
sqt="'"
croncmd1="root /bin/bash -c ${dqt}/usr/bin/certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.certbot/.secret/cloudflare.${domain}.ini --preferred-challenges dns -d ${sqt}*.${domain}${sqt} --cert-name "${domain}"  --non-interactive --force-renewal >> /var/log/certbot-cloudflare-api.log${dqt} && bash /etc/letsencrypt/.certbot/rename-LE-dir.sh ${domain} && systemctl restart nginx"
cronjob1="0 0 * * 0 $croncmd1"

#execute the first renewal
certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/.certbot/.secret/cloudflare.${domain}.ini --preferred-challenges dns -d "*.${domain}" --cert-name "${domain}" --non-interactive --agree-tos --email ${email} --force-renewal >> /var/log/certbot-cloudflare-api.log
$restartcmd

#puts the cronjob in /etc/cron.d/
printf "$cronjob1\n\n" > /etc/cron.d/$domain-wild-SSL

#bye bye message :)
printf "${GRN}\nWe're done!\n\n${NC}"

exit
