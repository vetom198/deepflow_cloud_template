#!/bin/bash
###
# preinstall
###
apt install wget curl sudo jq -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
### 
# parameters
###
OP_USER="tl_admin"
HOST_IP=$(hostname -I | awk '{print $1}')
DOCKER_COMPOSE_VERSION=1.29.2
PACKAGES=("net-tools","curl" "openssh-server" "nfs-common" "nfs-kernel-server" "gnupg2" "pass" "nvidia-container-runtime" )
USER_HOME=/home/${OP_USER}
AIPAAS_HOME=${USER_HOME}/workspace/aipaas

DEBIAN_FRONTEND=noninteractive
TZ=Etc/UTC

IMAGE_URL_PREFIX="https://deepflowinstall.blob.core.windows.net/installpackage/"

###
# Setup SSH
###
echo "Port 22" >> /etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
/etc/init.d/ssh restart

### 
# Create operation user
###

sudo useradd -m -s /bin/bash -G sudo ${OP_USER}
# sudo passwd ${OP_USER}


### create workspace
mkdir /home/${OP_USER}/workspace


### 
# Install packages
###

#install python 3.9
sudo apt install -y software-properties-common
sudo apt install -y python3.9
sudo apt install -y python3-pip
#install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io

pip install docker-compose

distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
for ((i=0; i < ${#PACKAGES[@]}; i++)); do (sudo apt install -y ${PACKAGES[$i]}); done

### 
# Setup keyless login
###

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t rsa -N '' <<<''
sudo -u user ssh-keygen -t rsa -N '' <<<''

cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
cp ~/.ssh/id_rsa.pub /home/$OP_USER/.ssh/authorized_keys

ssh-keyscan -H $HOST_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $HOST_IP >> /home/$OP_USER/.ssh/known_hosts

echo exit | ssh "$OP_USER@$HOST_IP"



# NODE_IMAGES=( \
#         ############ 運算機資源監控 #########
#         "prom/node-exporter:v1.0.0" \
#         "google/cadvisor:v0.33.0" \
#         "gpustatus-exporter:latest" \
#         ####################################
#         ############ Develop ###############
#         "nvcr.io/nvidia/tensorflow:21.06-tf2-py3-aipaas2.5" \
#         "nvcr.io/nvidia/pytorch:21.06-py3-aipaas2.5" \
#         "nvcr.io/nvidia/mxnet:21.06-py3-aipaas2.5" \
#         ####################################
#         ############ Harbor ###############
#         "goharbor/redis-photon:v2.2.2" \
#         "goharbor/trivy-adapter-photon:v2.2.2" \
#         "goharbor/harbor-registryctl:v2.2.2" \
#         "goharbor/registry-photon:v2.2.2.3MB" \
#         "goharbor/nginx-photon:v2.2.2.4MB" \
#         "goharbor/harbor-log:v2.2.2" \
#         "goharbor/harbor-jobservice:v2.2.2" \
#         "goharbor/harbor-core:v2.2.2" \
#         "goharbor/harbor-portal:v2.2.2.1MB" \
#         "goharbor/harbor-db:v2.2.2" \
#         "goharbor/prepare:v2.2.2" \
#         ####################################
#         )

# images_list=`docker images --format "{{.Repository}}:{{.Tag}}"`


# mkdir -p ~/workspace/aipaas-offline/node
# for ((i=0; i < ${#NODE_IMAGES[@]}; i++))
# do
#     fname=$(echo ${NODE_IMAGES[$i]} | sed 's/[/:]/_/g')
#     wget -P ~/workspace/aipaas-offline/node ${IMAGE_URL_PREFIX}portal/${fname}.tar
# done

# # portal
# cd ~/workspace/aipaas-offline
# for f in ./portal/*.tar; do
#     echo -e "${f} ... ..."
#     cat $f | docker load
# done

# # node
# cd ~/workspace/aipaas-offline
# for f in ./node/*.tar; do
#     echo -e "${f} ... ..."
#     cat $f | docker load
# done



###
# Download deepflow program
###

## download
wget -P ${USER_HOME}/workspace/deepflow.tar.gz http://web.ctyeh.com/deepflow.tar.gz
cd ${USER_HOME}/workspace/
tar zxvf FileName.tar.gz
# to be define


## initiallize

# cp local.py
cp ${AIPAAS_HOME}/backend/src/aipaas2/.env.sample ${AIPAAS_HOME}/backend/src/aipaas2/.env
cp ${AIPAAS_HOME}/backend/src/aipaas2/settings/local.azure.py ${AIPAAS_HOME}/backend/src/aipaas2/settings/local.py 
cp ${AIPAAS_HOME}/build_aipaas/install_script_shell/install_script_azure.sh ${AIPAAS_HOME}/install_script_azure.sh
cp ${AIPAAS_HOME}/build_aipaas/install_docker_compose/docker-compose-cloud.yml ${AIPAAS_HOME}/docker-compose.yml
sudo chmod +x ${AIPAAS_HOME}/install_script_azure.sh
# run aipaas installation
cd ${AIPAAS_HOME}
sudo sh install_script_azure.sh