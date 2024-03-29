# AutoRenewSSL-CloudFlareAPI
Auto renew Let's Encrypt wildcard SSL certificates through CloudFlare API


### ***Prerequisites:***

**1)** Being logged in as root 

**2)** Having a running nginx or apache web server

That's it!

### ***What's next:***

**1)** Install the AutoRenewSSL-CloudFlareAPI.sh file:
```bash
wget https://raw.githubusercontent.com/KeepSec-Technologies/AutoRenewSSL-CloudFlareAPI/main/AutoRenewSSL-CloudFlareAPI.sh
```

**3)** Make it executable:
```bash
chmod +x AutoRenewSSL-CloudFlareAPI.sh
```
**3)** Then run it: 
```bash
./AutoRenewSSL-CloudFlareAPI.sh
```

**3)** Answer the questions like the image below:

![image](https://user-images.githubusercontent.com/108779415/200984074-e85b127e-3740-4d88-a5a0-2eab62b9a895.png)


Notice how you can't use IIS or any web server other than nginx and apache.

**Like as it says in the script if you don't know what a CloudFlare API token is go to https://developers.cloudflare.com/fundamentals/api/get-started/create-token**

The cronjob is in **/etc/cron.d/[YOUR-DOMAIN]-wild-SSL** 
The cronjob logs is in **/var/log/certbot-cloudflare-api.log**

Note: the cronjob runs every week to make sure the certificate renew

*And we're done!*

If you want to uninstall it do:
```bash
rm -f /etc/cron.d/[YOUR-DOMAIN]-wild-SSL
rm -fr /etc/letsencrypt/.certbot
rm -fr /opt/certbot
```

Feel free to modify the code if there's something that you want to change.
