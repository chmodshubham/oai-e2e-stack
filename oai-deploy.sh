#!/bin/bash

# Define color constants for printing
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print sections with blue color
print_section() {
  echo -e "\n${BLUE}==================== $1 ====================${NC}\n"
}

# Function to print information with yellow color
print_info() {
  echo -e "${YELLOW}$1${NC}"
}

# Function to print success messages with green color
print_success() {
  echo -e "${GREEN}$1${NC}"
}

# Installing basic utilities
print_section "Installing Basic Utilities"
sudo apt update
sudo apt install -y git net-tools putty unzip
print_success "Basic utilities installed."

# Installing build tools and dependencies
print_section "Installing Build Dependencies"
sudo apt install -y autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool g++ \
  git inetutils-tools libboost-all-dev libncurses-dev libusb-1.0-0 libusb-1.0-0-dev libusb-dev \
  python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools \
  python3-ruamel.yaml libcap-dev libblas-dev liblapacke-dev libatlas-base-dev
print_success "Build dependencies installed."

# Cloning and building UHD v4.7.0.0
print_section "Cloning and Building UHD v4.7.0.0"
git clone https://github.com/EttusResearch/uhd.git ~/uhd
cd ~/uhd
git checkout v4.7.0.0
cd host
mkdir build && cd build
cmake ../
make -j $(nproc)
sudo make install
sudo ldconfig
sudo uhd_images_downloader
print_success "UHD installed and images downloaded."

# Installing libforms
print_section "Installing libforms"
sudo apt install -y libforms-dev libforms-bin
print_success "libforms installed."

# Cloning and building yaml-cpp
print_section "Cloning and Building yaml-cpp"
cd
git clone https://github.com/jbeder/yaml-cpp.git
cd yaml-cpp
mkdir build && cd build
cmake .. -DYAML_BUILD_SHARED_LIBS=ON
make
sudo make install
cd
sudo rm -r yaml-cpp/
print_success "yaml-cpp installed."

# Cloning OpenAirInterface5G repo
print_section "Cloning OpenAirInterface5G"
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git ~/openairinterface5g
cd ~/openairinterface5g
git checkout develop
print_success "OAI repo cloned and set to 'develop' branch."

# Building OAI dependencies
print_section "Building OAI Dependencies"
cd ~/openairinterface5g/cmake_targets
./build_oai -I
print_success "OAI dependencies installed."

# Final build with USRP + NRUE + gNB + nrscope
print_section "Final Build with USRP + NRUE + gNB + nrscope"
./build_oai -w USRP --ninja --nrUE --gNB --build-lib "nrscope" -C
print_success "Build completed!"

# Installing Docker
print_section "Installing Docker"
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repo to APT sources..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -a -G docker $(whoami)
print_success "Docker installed."

# Script to create the new script file: download_oai_cn5g.sh
TARGET_SCRIPT="download_oai_cn5g.sh"

# Creating the download_oai_cn5g.sh script
cat << EOF > "$TARGET_SCRIPT"
#!/bin/bash

# Function definitions (assumed to be used here)
print_section() {
  echo -e "\n\e[1;34m==================== \$1 ====================\e[0m\n"
}

print_success() {
  echo -e "\e[1;32m\$1\e[0m"
}

# Downloading OAI CN5G Docker Compose setup
print_section "Downloading OAI CN5G Docker Setup"
wget -O ~/oai-cn5g.zip "https://gitlab.eurecom.fr/oai/openairinterface5g/-/archive/develop/openairinterface5g-develop.zip?path=doc/tutorial_resources/oai-cn5g"
unzip ~/oai-cn5g.zip
mv ~/openairinterface5g-develop-doc-tutorial_resources-oai-cn5g/doc/tutorial_resources/oai-cn5g ~/oai-cn5g
rm -r ~/openairinterface5g-develop-doc-tutorial_resources-oai-cn5g ~/oai-cn5g.zip
cd ~/oai-cn5g
docker compose pull
print_success "OAI CN5G setup downloaded and pulled."
EOF

# Making the new script executable
chmod +x "$TARGET_SCRIPT"

# Final message with reboot instruction
echo -e "\n\e[1;32mCreated script: $TARGET_SCRIPT\e[0m"
print_success "Run download_oai_cn5g.sh after reboot. Rebooting..."

# Reboot the system
sudo reboot
