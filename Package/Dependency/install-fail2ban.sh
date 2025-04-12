#!/usr/bin/env bash

# Cause the script to exit on any errors
# Reference: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euo pipefail

# extends the sudo timeout for another 15 minutes
sudo -v

# install fail2ban
sudo apt install fail2ban -y

# allow 127.0.0.1
echo '
[DEFAULT]

bantime  = 86400
ignoreip = 127.0.0.1/8
' | sudo tee /etc/fail2ban/jail.local

# restart fail2ban
sudo service fail2ban restart
