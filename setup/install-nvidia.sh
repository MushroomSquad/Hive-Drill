#!/usr/bin/env bash
# Установка NVIDIA Container Toolkit (Ubuntu / Debian / WSL2)
set -euo pipefail

echo "=== NVIDIA Container Toolkit ==="

# Определяем дистрибутив
. /etc/os-release
DISTRO="${ID}${VERSION_ID}"
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)

echo "Дистрибутив: $DISTRO / $ARCH"

# Добавляем репозиторий NVIDIA
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update -q
sudo apt-get install -y nvidia-container-toolkit

# Настраиваем Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

echo ""
echo "Проверка:"
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
