# MailPlus_haproxy

HAProxy is in front of Synology DSM for protection and to provide a public ip for the device.  
For some environments it is easier to setup Synology and provide services such as MailPlus (postfix) along with a modern mail web interface.

Synology DSM and HAproxy are hosted in different locations, they are connected by a 5G network and an OpenVPN connection.

The HAProxy configuration as follows while limiting which domain or subdomain have access to the service:
```
# Frontend: smtp_secure_services ()
frontend smtp_secure_services
    bind 0.0.0.0:465 name 0.0.0.0:465 ssl  crt-list /tmp/haproxy/ssl/65474fb5e5d3c3.14799387.certlist 
    mode tcp
    # ACL: sni_match
    acl acl_65586fb38b7b27.62875184 ssl_fc_sni site.onedot.cloud

    # ACTION:
    use_backend smtp_over_tls if acl_65586fcda6a671.46584412 || acl_6558d04c0b3f30.88935253 || acl_65586fb38b7b27.62875184

# Backend: smtps ()
backend smtp_over_tls
    # health checking is DISABLED
    mode tcp
    balance source
    # stickiness
    stick-table type ip size 50k expire 30m  
    stick on src
    server SMTP_Over_TLS 10.10.10.250:465 ssl verify none send-proxy
```

The following option have to be added to Postfix master.cf file:  
```
465 inet n - n - - smtpd
 -o smtpd_tls_wrappermode=yes
 -o smtpd_sasl_auth_enable=yes
 -o smtpd_client_restrictions=permit_sasl_authenticated,reject
**-o smtpd_upstream_proxy_protocol=haproxy**
 -o cleanup_service_name=auth-cleanup
```

# MailPlus Package notes
* The MailPlus package can accept custom main.cf configuration that is not effected by reboot or service restart by creating and editing the file /var/packages/MailPlus-Server/etc/customize/postfix/main.cf. The proper permission is rw-r--r--.  
* Postfix bin is located at ~# /var/packages/MailPlus-Server/target/sbin/postfix check

# General notes
* In my configuration I have not added haproxy as a trusted network source, be caution that any miss configuration to your server might result in open relay.
* Try to limit the ip source to your device while testing, to connect with the service use openssl:  
~$ openssl s_client -connect site.onedot.cloud:465
after the initial greeting you can send an EHLO command;  
read R BLOCK
EH220 site.onedot.cloud ESMTP Postfix
**EHLO localhost**
250-site.onedot.cloud
250-PIPELINING
250-SIZE 52428800
250-ETRN
250-AUTH PLAIN LOGIN
250-AUTH=PLAIN LOGIN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250-DSN
250 SMTPUTF8
**auth login**
334 VXNlcm5hbWU6
**VXNlcm5hbWU6**
334 UGFzc3dvcmQ6
**VXNlcm5hbWU6**
221 2.7.0 Error: 181.11.111.111 is blocked.
closed

So, The bash script in this repository shall be added as a cron job / DSM Task Scheduler to check for the current master.cf smtps options and add the following if not exist:  
-o smtpd_upstream_proxy_protocol=haproxy  
adjust the script to your need.


References:
[mailplus_team @ Synology community](https://community.synology.com/enu/forum/17/post/103387).
[MailPlus Server with multiple domains and multiple IPs - done properly By vlad2000](https://community.synology.com/enu/forum/8/post/163585).
[lucho @ Synology community](https://community.synology.com/enu/forum/17/post/115087).

* one ChatGPT has been harmed during this proccess.
