#!/bin/bash
# ----------------------------------------------------------------------------
# user-data.bash
# ----------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LC_ALL=${LANG}

yum -y update

yum install -y httpd.x86_64

systemctl start httpd.service

systemctl enable httpd.service

echo "<h1>Altais test infra<h1> <br/> <img src='https://github.com/arley9511/altais-sre-coding-challenge/blob/7662d59e78fcaa445b179b78f8a1c87ec4a62bb7/files/altais-infra.png?raw=true' alt='diagram'/>" > /var/www/html/index.html
