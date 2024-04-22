#!/bin/bash

# Check if domain input was provided
if [ -z "$1" ]; then
    echo "Usage: $0 [domain-prefix]"
    echo "Example: $0 wild.example.org"
    exit 1
fi

# Input domain prefix
INPUT=$1
CERTBOT="/usr/bin/certbot"
SERVER_URL="https://acme-v02.api.letsencrypt.org/directory"
DNS_PLUGIN="--dns-cloudflare"
CREDENTIALS_PATH="/etc/letsencrypt/.certbot/.secret/cloudflare.$INPUT.ini"
DOMAIN="*.$INPUT"
CERT_NAME="$INPUT"

# Function to delete old numbered certificates
function cleanup_numbered_certs() {
    echo "Checking for and cleaning up numbered certificates..."
    for cert in /etc/letsencrypt/live/${CERT_NAME}-*; do
        if [ -d "$cert" ]; then
            numbered_cert_name=$(basename "$cert")
            echo "Deleting old numbered certificate: $numbered_cert_name"
            $CERTBOT delete --cert-name "$numbered_cert_name" --non-interactive
        fi
    done
    rm -rf /etc/letsencrypt/live/$CERT_NAME*
    rm -rf /etc/letsencrypt/archive/$CERT_NAME*
    rm -rf /etc/letsencrypt/renewal/$CERT_NAME*
}

# Clean up any existing numbered certificates first
cleanup_numbered_certs

# Renew the wildcard certificate
echo "Renewing wildcard certificate for $DOMAIN"
$CERTBOT certonly \
    --server $SERVER_URL \
    $DNS_PLUGIN \
    --dns-cloudflare-credentials $CREDENTIALS_PATH \
    --preferred-challenges dns \
    -d $DOMAIN \
    --cert-name $CERT_NAME \
    --non-interactive \
    --force-renewal

# Test Nginx configuration
#echo "Testing Nginx configuration..."
#nginx -t
#if [ $? -eq 0 ]; then
#    echo "Nginx configuration is valid. Reloading Nginx..."
#    nginx -s reload
#    echo "Nginx has been successfully reloaded."
#else
#    echo "Error in Nginx configuration. Please check and correct the configuration."
#fi

# Final status check
if [ $? -eq 0 ]; then
    echo "Certificate renewal and Nginx reload completed successfully for $DOMAIN"
else
    echo "An issue occurred during the renewal or Nginx reload process."
fi
