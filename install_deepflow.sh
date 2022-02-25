### 
# parameters
###
HOST_IP=$(hostname -I | awk '{print $1}')
DOCKER_COMPOSE_VERSION=1.29.2
PACKAGES=( \
            ### required
            "curl" \
            "openssh-server" \
            ### nfs tools
            "nfs-common" \
            "nfs-kernel-server" \
            ### harbor
            "gnupg2" \
            "pass" \
            ### nvidia-docker
            "nvidia-container-runtime" \
            ### optional tools
            # "openssl" \
            # "git" \
            # "curl" \
            # "wget" \
            # "vim" \
            # "tmux" \
            # "tree" \
            # "netcat" \
            # "net-tools" \
            # "libpq-dev" \
            # "zip" \
            # "unzip" \
            # "ntfs-3g" \
            # "fuse" \
            )

### 
# Create operation user
###
OP_USER="tl_admin"
sudo useradd -m -s /bin/bash -G sudo ${OP_USER}
sudo passwd ${OP_USER}

### 
# Install packages
###

sudo apt-get update
for ((i=0; i < ${#PACKAGES[@]}; i++)); do (sudo apt install -y ${PACKAGES[$i]}); done


### 
# Setup keyless login
###

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen
cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys
ssh-keyscan -H $HOST_IP >> ~/.ssh/known_hosts
echo exit | ssh "$OP_USER@$HOST_IP"

### 
# Install Docker Compose
###


sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
