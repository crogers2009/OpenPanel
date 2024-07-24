#!/bin/bash
################################################################################
# Script Name: INSTALL.sh
# Description: Install the latest version of OpenPanel
# Usage: cd /home && (curl -sSL https://get.openpanel.co || wget -O - https://get.openpanel.co) | bash
# Author: Stefan Pejcic
# Created: 11.07.2023
# Last Modified: 16.07.2024
# Company: openpanel.co
# Copyright (c) OPENPANEL
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################


# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Defaults
CUSTOM_VERSION=false
INSTALL_TIMEOUT=600 # 10 min
DEBUG=false
SKIP_APT_UPDATE=false
SKIP_IMAGES=false
REPAIR=false
LOCALES=true
NO_SSH=false
INSTALL_FTP=false
INSTALL_MAIL=false
OVERLAY=false
IPSETS=true
SET_HOSTNAME_NOW=false
SETUP_SWAP_ANYWAY=false
SWAP_FILE="1"
SELFHOSTED_SCREENSHOTS=false
SEND_EMAIL_AFTER_INSTALL=false
SET_PREMIUM=false

# Paths
ETC_DIR="/etc/openpanel/"
LOG_FILE="openpanel_install.log"
LOCK_FILE="/root/openpanel.lock"
OPENPANEL_DIR="/usr/local/panel/"
OPENPADMIN_DIR="/usr/local/admin/"
OPENCLI_DIR="/usr/local/admin/scripts/"
OPENPANEL_ERR_DIR="/var/log/openpanel/"
SERVICES_DIR="/etc/systemd/system/"
TEMP_DIR="/tmp/"

# Domains
SCREENSHOTS_API_URL="http://screenshots-api.openpanel.co/screenshot"

# Redirect output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# ... [rest of the script remains the same until the install_openadmin function] ...

install_openadmin(){
    # OpenAdmin
    #
    # https://openpanel.co/docs/admin/intro/
    #
    echo "Setting up Admin panel.."

    if [ "$REPAIR" = true ]; then
        rm -rf $OPENPADMIN_DIR
    fi
    
    mkdir -p $OPENPADMIN_DIR

    # Get current Python version
    current_python_version=$(python3 --version 2>&1 | cut -d " " -f 2 | cut -d "." -f 1,2 | tr -d '.')
    echo "Current Python version: $current_python_version"

    # Ubuntu 22
    if [ -f /etc/os-release ] && grep -q "Ubuntu 22" /etc/os-release; then   
        echo "Downloading files for Ubuntu22 and python version $current_python_version"
        git clone -b $current_python_version --single-branch https://github.com/stefanpejcic/openadmin $OPENPADMIN_DIR
        cd $OPENPADMIN_DIR
        debug_log pip install -r requirements.txt
    # Ubuntu 24
    elif [ -f /etc/os-release ] && grep -q "Ubuntu 24" /etc/os-release; then
        echo "Downloading files for Ubuntu24 and python version $current_python_version"
        git clone -b $current_python_version --single-branch https://github.com/stefanpejcic/openadmin $OPENPADMIN_DIR
        cd $OPENPADMIN_DIR
        debug_log pip install -r requirements.txt --break-system-packages

        # on ubuntu24 we need to use overlay instead of devicemapper!
        OVERLAY=true
        
    # Debian
    elif [ -f /etc/debian_version ]; then
        echo "Installing PIP and Git"
        apt-get install git python3-pip -y > /dev/null 2>&1
        echo "Downloading files for Debian and python version $current_python_version"
        git clone -b "debian-$current_python_version" --single-branch https://github.com/stefanpejcic/openadmin "$OPENPADMIN_DIR" || {
            echo "Failed to clone the repository. Falling back to main branch."
            git clone https://github.com/stefanpejcic/openadmin "$OPENPADMIN_DIR"
        }
        cd "$OPENPADMIN_DIR" || exit
        if [ -f requirements.txt ]; then
            debug_log pip3 install -r requirements.txt
            debug_log pip3 install -r requirements.txt --break-system-packages
        else
            echo "requirements.txt not found in $OPENPADMIN_DIR"
            ls -la  # List directory contents for debugging
        fi
    # other
    else
        echo "Unsupported OS. Currently only Ubuntu22-24 and Debian11-12 are supported."
        exit 1
    fi

    cp -fr /usr/local/admin/service/admin.service ${SERVICES_DIR}admin.service  > /dev/null 2>&1
    
    systemctl daemon-reload  > /dev/null 2>&1
    service admin start  > /dev/null 2>&1
    systemctl enable admin  > /dev/null 2>&1
}

# ... [rest of the script remains the same] ...
