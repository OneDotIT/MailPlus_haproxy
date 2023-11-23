#!/bin/bash

# Path to master.cf
 MASTER_CF="/var/packages/MailPlus-Server/target/etc/master.cf"

# Path to postfix binary
 POSTFIX_BIN="/var/packages/MailPlus-Server/target/sbin/postfix"

# Option to check/add
 OPTION=" -o smtpd_upstream_proxy_protocol=haproxy"

# wait for the service to start, ~ 1 minute, we do 5.
 sleep 300

# Check if the option exists in the 465 service configuration
if grep -q "465 inet.*smtpd" "$MASTER_CF" && ! grep -qF $OPTION "$MASTER_CF"; then
    # Option does not exist, inject the command
    echo "Adding $OPTION to $MASTER_CF"

    sed -i '/^465 inet.*smtpd/a \ \n'"$OPTION # added by script" "$MASTER_CF"

    # Reload postfix
    echo "Reloading Postfix"
    $POSTFIX_BIN reload
else
    echo "Option $OPTION already exists or 465 inet service not found in $MASTER_CF"
fi
