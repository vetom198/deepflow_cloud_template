#!/bin/bash
###
# preinstall
###
apt install wget curl sudo jq -y
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
### 
# parameters
###
HOST_IP=$(hostname -I | awk '{print $1}')
DOCKER_COMPOSE_VERSION=1.29.2
PACKAGES=("curl" "openssh-server" "nfs-common" "nfs-kernel-server" "gnupg2" "pass" "nvidia-container-runtime" )


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
OP_USER="tl_admin"
sudo useradd -m -s /bin/bash -G sudo ${OP_USER}
# sudo passwd ${OP_USER}

### 
# Install packages
###


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

# Download images
PORTAL_IMAGES=( \
        ############ AIPAAS元件 ############
        "kong:custom" \
        "django:latest" \
        "aipaas_aipaas_frontend:latest" \
        "aipaas_nginx:latest" \
        "aipaas/aipaas_fluentd:1.9.1" \
        "aipaas_explain:v1.0" \
        "file_profiling:v1.0" \
        "postgres:13" \
        "pantsel/konga:next" \
        "bitnami/redis:latest" \
        "portainer/portainer:latest" \
        "grafana/grafana:latest" \
        "prom/prometheus:latest" \
        "prom/node-exporter:v1.0.0" \
        "google/cadvisor:v0.33.0" \
        "gpustatus-exporter:latest" \
        ####################################
        ############ 模型健康度 #############
        "mongo:4.2.9" \
        "aipaas/aipaas_model_health_agent:1.0" \
        "aipaas/aipaas_model_health_flask:1.0" \
        ####################################
        ############ 財稅案 #################
        # "registry.gitlab.com/chunghwatelecom/ai/fiadata:latest" \
        # "postgres:9.6-alpine" \
        ####################################
        )

NODE_IMAGES=( \
        ############ 運算機資源監控 #########
        "prom/node-exporter:v1.0.0" \
        "google/cadvisor:v0.33.0" \
        "gpustatus-exporter:latest" \
        ####################################
        ############ Develop ###############
        "nvcr.io/nvidia/tensorflow:21.06-tf2-py3-aipaas2.5" \
        "nvcr.io/nvidia/pytorch:21.06-py3-aipaas2.5" \
        "nvcr.io/nvidia/mxnet:21.06-py3-aipaas2.5" \
        ####################################
        ############ Harbor ###############
        "goharbor/redis-photon:v2.2.2" \
        "goharbor/trivy-adapter-photon:v2.2.2" \
        "goharbor/harbor-registryctl:v2.2.2" \
        "goharbor/registry-photon:v2.2.2.3MB" \
        "goharbor/nginx-photon:v2.2.2.4MB" \
        "goharbor/harbor-log:v2.2.2" \
        "goharbor/harbor-jobservice:v2.2.2" \
        "goharbor/harbor-core:v2.2.2" \
        "goharbor/harbor-portal:v2.2.2.1MB" \
        "goharbor/harbor-db:v2.2.2" \
        "goharbor/prepare:v2.2.2" \
        ####################################
        ############ AutoML ################
        "aipaas/automl:cuda10.2-py37" \
        ####################################
        ############ 數據探索 ###############
        "file_profiling:v1.0" \
        ####################################
        ############ 模型部署 ###############
        "mlflow_cpu:latest" \
        "bentoml:v1" \
        ####################################
        )

images_list=`docker images --format "{{.Repository}}:{{.Tag}}"`
echo "Download deepflow images"
mkdir -p ~/workspace/aipaas-offline/portal
for ((i=0; i < ${#PORTAL_IMAGES[@]}; i++))
do
    fname=$(echo ${PORTAL_IMAGES[$i]} | sed 's/[/:]/_/g')
    wget -P ~/workspace/aipaas-offline/portal/ ${IMAGE_URL_PREFIX}portal/${fname}.tar
done

mkdir -p ~/workspace/aipaas-offline/node
for ((i=0; i < ${#NODE_IMAGES[@]}; i++))
do
    fname=$(echo ${NODE_IMAGES[$i]} | sed 's/[/:]/_/g')
    wget -P ~/workspace/aipaas-offline/node ${IMAGE_URL_PREFIX}portal/${fname}.tar
done

# portal
cd ~/workspace/aipaas-offline
for f in ./portal/*.tar; do
    echo -e "${f} ... ..."
    cat $f | docker load
done

# node
cd ~/workspace/aipaas-offline
for f in ./node/*.tar; do
    echo -e "${f} ... ..."
    cat $f | docker load
done