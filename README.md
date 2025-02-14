# AutoRenewSSL-CloudFlareAPI
Auto renew Let's Encrypt wildcard SSL certificates through CloudFlare API


### ***Prerequisites:***

**1)** Being logged in as root or sudo

**2)** Having a running nginx or apache web server

That's it!

### ***What's next:***

**1)** Get the AutoRenewSSL-CloudFlareAPI.sh script:
```bash
curl -O https://raw.githubusercontent.com/KeepSec-Technologies/AutoRenewSSL-CloudFlareAPI/main/AutoRenewSSL-CloudFlareAPI.sh
```

**3)** Make it executable:
```bash
chmod +x AutoRenewSSL-CloudFlareAPI.sh
```
**3)** Then run it as sudo or root: 
```bash
sudo ./AutoRenewSSL-CloudFlareAPI.sh
```

**3)** Answer the questions like the image below:

![image](https://github.com/user-attachments/assets/bb88800a-960e-446c-b854-bb9672223a3a)

**Like as it says in the script if you don't know what a CloudFlare API token is go to https://developers.cloudflare.com/fundamentals/api/get-started/create-token**

The cronjob is located at **/etc/cron.d/[YOUR-DOMAIN]-wild-SSL** 
The cronjob logs is located at **/var/log/certbot-cloudflare-api.log**

Note: the cronjob runs every day at 12AM to make sure the certificate renews, only renews when it expires in 30 days.

*And we're done!*

If you want to uninstall everything it does, do:
```bash
rm -f /etc/cron.d/[YOUR-DOMAIN]-wild-SSL
rm -fr /etc/letsencrypt/.certbot
rm -fr /opt/certbot
```

Feel free to modify the code if there's something that you want to change.
