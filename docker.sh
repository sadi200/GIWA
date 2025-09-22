#!/bin/bash
# 1️⃣ Update system
sudo apt update && sudo apt upgrade -y
# 2️⃣ Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
# 3️⃣ Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# 4️⃣ Set up the Docker stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# 5️⃣ Update package index again
sudo apt update
# 6️⃣ Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io
# 7️⃣ Install Docker Compose plugin
sudo apt install -y docker-compose-plugin
# 8️⃣ Verify Docker & Compose versions
docker --version && docker compose version
