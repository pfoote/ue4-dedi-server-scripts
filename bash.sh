#!/bin/bash
# Tested with Ubuntu 16.04.2 LTS ec2 ami

# change these settings
SERVER_HOSTNAME="*****************"
PUBLIC_IP="***.***.***.***"
SERVER_TIMEZONE="GMT"
INSTALL_PREFIX="/ue4"
UE4_GAME_NAME="UE4-Game"
GAMESERVERZIP_URL="********************"

# pre-requisites
STEAMCMDZIP_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
APT_PKG_LIST="tmux unzip awscli lib32gcc1"
# hostname
echo "Setting hostname"
echo $SERVER_HOSTNAME > /etc/hostname
hostname `cat /etc/hostname`
# timezone
echo "Setting timezone"
echo $SERVER_TIMEZONE | sudo tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata
# directories
echo "Making directories"
mkdir ${INSTALL_PREFIX}
chown ubuntu:ubuntu ${INSTALL_PREFIX}
mkdir ${INSTALL_PREFIX}/downloads
mkdir ${INSTALL_PREFIX}/steamcmd
# downloads
echo "Grabbing ${UE4_GAME_NAME}-server.zip"
wget -q $GAMESERVERZIP_URL -O ${INSTALL_PREFIX}/downloads/${UE4_GAME_NAME}-server.zip
echo "Grabbing steamcmd_linux.tar.gz"
wget -q $STEAMCMDZIP_URL -O ${INSTALL_PREFIX}/downloads/steamcmd_linux.tar.gz
# apt installs
echo "Updating apt sources"
apt-getl -qq update
echo "Installing apt packages"
apt-get -qq --yes --force-yes install $APT_PKG_LIST
# install game
echo "Installing ${UE4_GAME_NAME}-server"
cd ${INSTALL_PREFIX}
unzip ${INSTALL_PREFIX}/downloads/${UE4_GAME_NAME}-server.zip
chmod +x ${INSTALL_PREFIX}/${UE4_GAME_NAME}/Binaries/Linux/${UE4_GAME_NAME}Server
# install steamcmd
echo "Installing steamcmd"
cd ${INSTALL_PREFIX}/steamcmd
tar -zxf ${INSTALL_PREFIX}/downloads/steamcmd_linux.tar.gz
# init steamcmd
${INSTALL_PREFIX}/steamcmd/steamcmd.sh +quit
# copy steam client library to INSTALL_PREFIX
echo "Copying steamcmd files to ${UE4_GAME_NAME} directory"
cp ${INSTALL_PREFIX}/steamcmd/linux64/steamclient.so /${INSTALL_PREFIX}/${UE4_GAME_NAME}/Binaries/Linux/steamclient.so
# final chown
echo "Final permission fixup"
chown -R ubuntu:ubuntu ${INSTALL_PREFIX}
# get ec2 metadata
echo "Getting EC2 metadata"
EC2_INSTANCE_ID="`ec2metadata --instance-id`"
EC2_INSTANCE_REGION="`ec2metadata --availability-zone | sed 's/.$//'`"
# retake EIP if specified
if [ $PUBLIC_IP ]; then
	echo "Attaching Elastic IP address"
	aws --region $EC2_INSTANCE_REGION ec2 associate-address --public-ip $PUBLIC_IP --instance-id $EC2_INSTANCE_ID
fi
# run game
echo "Running ${UE4_GAME_NAME} server binary"
sudo -u ubuntu tmux new-session -d "${INSTALL_PREFIX}/${UE4_GAME_NAME}/Binaries/Linux/${UE4_GAME_NAME}Server"

