#!/usr/bin/env bash

# Cause the script to exit on any errors
# Reference: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail
set -euo pipefail

# change to /tmp
cd /tmp

# useful variables
DRIVER_VERSION="570.153.02" # CUDA Version: 12.4
DRIVER_INSTALLER="NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"
DRIVER_LINK="http://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/${DRIVER_INSTALLER}"

# extends the sudo timeout for another 15 minutes
sudo -v

# check whether secure boot status for driver installation
check_secure_boot_status () {
  if sudo dmidecode -t 2 | grep -q "ASUSTeK"; then
    if sudo mokutil --sb-state | grep -q "enabled"; then
      echo "Please Disable Secure Boot for ASUS Motherboard"
      return 1
    fi
  fi
}

check_secure_boot_status
# download installer
printf "Downlodaing NVIDIA driver ${DRIVER_VERSION} installer... "
curl -sSL "${DRIVER_LINK}" -o "${DRIVER_INSTALLER}"
chmod +x "${DRIVER_INSTALLER}"
echo "Done."

#stop lightdm
services=$(service --status-all | grep '+' || true)
if echo $services | grep -Fq 'lightdm'; then
  printf "Stopping lightdm... "
  sudo service lightdm stop
  echo "Done."
fi

# stop nvidai-persistenced
if systemctl is-active --quiet nvidia-persistenced; then
  printf "Stopping nvidia-persistenced... "
  sudo systemctl stop nvidia-persistenced
  echo "Done."
fi

# install NVIDIA driver
printf "Installing NVIDIA driver ${DRIVER_VERSION}... "
sudo ./"${DRIVER_INSTALLER}" --silent --dkms --no-cc-version-check
echo "Done."

# restart or install nvidia-persistenced
if systemctl list-unit-files | grep -q nvidia-persistenced; then
  printf "Restarting nvidia-persistenced... "
  sudo systemctl restart nvidia-persistenced
  echo "Done."
else
  echo "nvidia-persistenced not found. Installing nvidia-persistenced ..."

  NV_PERSISTENCED_TAR="/usr/share/doc/NVIDIA_GLX-1.0/samples/nvidia-persistenced-init.tar.bz2"
  NV_PERSISTENCED_DIR="nvidia-persistenced-init"

  if [ -f "$NV_PERSISTENCED_TAR" ]; then
    printf "Installing nvidia-persistenced... "
    tar -xf $NV_PERSISTENCED_TAR -C .
    cd $NV_PERSISTENCED_DIR
    sudo ./install.sh
    cd ..
    echo "Done."
  else
    echo "Warning: nvidia-persistenced init scripts not found at $NV_PERSISTENCED_TAR"
    echo "You may need to install nvidia-persistenced manually."
  fi
fi

# restart lightdm
if service --status-all | grep -Fq 'lightdm'; then
  printf "Restarting lightdm... "
  sudo service lightdm restart
  echo "Done."
fi

# clean up
rm "${DRIVER_INSTALLER}"

