#!/bin/bash
#
# Author: justinKocian
#
# Post install setup script that can be used to perform maintenance after a VM is cloned,
# install useful packages, and install Docker with Portainer (both full and agent).
#
# ### PART ONE: Initial post-install steps
#   1. Prompts for user input to confirm OS and determine what of the available options should be taken.
#       - Change hostname
#       - Reset machine ID (useful for proxmox clones)
#       - Add a non-root user
#       - Create SSH keys (future: copy over new keys or skip creating new keys and instead copy existing keys from remote servers)
#   2. Creates directories
#   3. Implement selected changes
#
# ### PART TWO: Package installations and apt maintenance
#   1. Runs apt updates and upgrades
#   2. Installs curl, wget,git, moreutils, and net-tools
#   3. Runs apt clean, autoclean, and autoremove
#
# ### PART THREE: Docker install and config
#   1. Checks to see if Docker or Docker-compose are installed, if not prompts for user input
#   2. Installs Docker and Docker-compose, creates directories, adds current user to docker group, starts Docker service
#   3. Prompts for available containers
#   4. Downloads the docker-compose file and runs docker-compose up -d

gatherInput()
{
    clear
    OS="$REPLY" ## <-- This $REPLY is about OS Selection

    # What are you wanting to do out of the options provided?
    echo "PART ONE: Initial post-install steps"
    echo ""
    read -p "Change machine hostname? (y/n): " HOST
    read -p "Reset machine ID? (y/n): " RMID
    read -p "Add new user? (y/n): " NUSR
    read -p "Generate new SSH keys? (y/n): "

    systemSetup
}

systemSetup()
{
    # Create directories
    cd ~
    sudo mkdir -p docker/apps logs

    systemConfig
}

systemConfig()
{
    # Change hostname
    if [[ "$HOST" == [yY] ]]; then
        # Set a new hostname
        read -p "Please type the desired hostname: " NEW_HOSTNAME

        sudo hostnamectl set-hostname "$NEW_HOSTNAME"
    else
        echo "Hostname was not reset."
        echo ""
    fi

    # Reset machine ID
    if [[ "$RMID" == [yY] ]]; then
        rm -f /etc/machine-id /var/lib/dbus/machine-id
        dbus-uuidgen --ensure=/etc/machine-id
        dbus-uuidgen --ensure
    else
        echo "Machine ID was not reset."
    fi

    # Add non-root user
    if [[ "$NUSR" == [yY] ]]; then
        read -rp "Username: " USER

        adduser --disabled-password --gecos "" $USER
        adduser $USER sudo
        mkdir /home/$USER/.ssh
        cp .ssh/authorized_keys /home/$USER/.ssh
        chown -R $USER:$USER /home/$USER/.ssh
        chmod 640 /etc/sudoers
        echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        chmod 440 /etc/sudoers
        echo "user $USER created."
    else
        echo "No new user was added."
    fi

    # Add SSH keys
    if [[ $SSH == [yY] ]]; then
        ssh-keygen
    else
        echo "No SSH keys added."
        echo ""
        echo "If there is an existing public key available, please remember to copy it to the machine."
    fi

    echo "Initial configurations complete."
    echo ""
    echo "Moving on to common package installations."

    gatherInput2
}

### PART TWO: Package installations and apt maintenance

gatherInput2()
{
    echo "PART TWO: Package installations and apt maintenance"
    echo ""
    # What are you wanting to do out of the options provided?
    #echo "Please select the packages or tools you would like to install."
    #echo ""
    #echo ""

    #read -p "Terraform (y/n): " TERR
    #read -p "Ansible (y/n): " ANSI
    #read -p "Packer (y/n): " PACK
    #read -p "Speedtest (y/n): " SPED

    packageInstall
}

packageInstall()
{
    # Updates and upgrades
    echo "Running apt updates and upgrades."
    echo ""
    sudo apt update && sudo apt upgrade -y

    # Install tools
    echo "Installing common tools."
    echo ""
    sudo apt install curl wget git moreutils net-tools -y

    cleanup
}

cleanup()
{
    echo "Cleaning up the system."
    echo ""
    # Refresh apt cache
    sudo apt clean
    sudo apt autoclean

    # Uninstall unused packages
    sudo apt autoremove

    echo "Package installations complete."
    echo "Moving on."
    echo ""
    echo ""

    gatherInput3
}

### PART THREE: Docker install and config

gatherInput3()
{
    echo "PART THREE: Docker install and config"
    echo ""

    # Try to check whether docker is installed and running - don't prompt if it is
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    ISCOMP=$( (docker-compose -v ) 2>&1 )

    # Docker
    if [[ "$ISACT" != "active" ]]; then
        read -rp "Install Docker CE? (y/n): " DOCK # <-- Prompt one
    else
        echo "Docker appears to be installed and running."
        echo ""
        echo ""
    fi

    # Docker-Compose
    if [[ "$ISCOMP" == *"command not found"* ]]; then
        read -rp "Install Docker-Compose? (y/n): " DCOMP # <-- Prompt two
    else
        echo "Docker-compose appears to be installed."
        echo ""
        echo ""
    fi

    read -rp "Install Portainer? (y/n): " PTAIN # <-- Prompt three

    # Portainer
    if [[ "$PTAIN" == [yY] ]]; then
        echo ""
        echo ""
        PS3="Please choose either Portainer-CE or just Portainer Agent: "
        select _ in \
            " Full Portainer (Web GUI for Docker, Swarm, and Kubernetes)" \
            " Portainer Agent - Remote Agent to Connect from Portainer" \
            " Nevermind -- I don't need Portainer after all."
        do
            PORT="$REPLY"
            case $REPLY in
                1) dockerInstall ;;
                2) dockerInstall ;;
                3) dockerInstall ;;
                *) echo "Invalid selection, please try again..." ;;
            esac
        done
    fi

    dockerInstall
}

dockerInstall()
{
    # Install Docker CE
    if [[ "$OS" == [234] ]]; then
        if [[ "$ISACT" != "active" ]]; then
            echo "Installing Docker-CE (Community Edition)..."
            sleep 2s

        
            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1
            echo "- docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "          "${DOCKERV}
            sleep 3s

            # Start Docker service
            echo "Starting Docker Service"
            sudo systemctl docker start >> ~/docker-script-install.log 2>&1
        fi
    fi

    # Add $USER to Docker group
    if [[ "$ISACT" != "active" ]]; then
        if [[ "$DOCK" == [yY] ]]; then
            # add current user to docker group so sudo isn't needed
            echo ""
            echo "Attempting to add the currently logged in user to the docker group."

            sleep 2s
            sudo usermod -aG docker "${USER}" >> ~/docker-script-install.log 2>&1
            echo "  - You'll need to log out and back in to finalize the addition of your user to the docker group."
            echo ""
            echo ""
            sleep 3s
        fi
    fi

    sleep 2s
    
    # Install Docker-Compose
    if [[ "$OS" == "2" || "$OS" == "3" || "$OS" == "4" ]]; then
        VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
        sudo curl -SL https://github.com/docker/compose/releases/download/$VERSION/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
        #sudo curl -L "https://github.com/docker/compose/releases/download/$(curl https://github.com/docker/compose/releases | grep -m1 '<a href="/docker/compose/releases/download/' | grep -o 'v[0-9:].[0-9].[0-9]')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        sleep 2
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Test if Docker service is running
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if [[ "$ISACt" != "active" ]]; then
        echo "Giving the Docker service time to start."
        while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
            sudo systemctl start docker >> ~/docker-script-install.log 2>&1
            sleep 10s &
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
            ISACT=`sudo systemctl is-active docker`
            let X=X+1
            echo "$X"
        done
    fi

    # Create Docker network
    sudo docker network create primary-network
    sleep 2s

    installApps
}

installApps()
{
    # Install Portainer
    if [[ "$PORT" == "1" ]]; then
        echo "1. Preparing to Install Portainer-CE"
        echo ""
        echo "2. Creating the folder structure for Portainer."
        echo "3. You can find Portainer-CE files in ./docker/portainer"

        #sudo docker volume create portainer_data >> ~/docker-script-install.log 2>&1
        mkdir -p docker/portainer/portainer_data
        cd docker/portainer
        curl https://raw.githubusercontent.com/jkocianICA/ica-it-compose/main/Portainer_docker-compose.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
        echo ""

        # Start Portainer container
        echo "Starting Portainer..."
        echo ""
        sudo docker-compose up -d

        echo ""
        echo "Navigate to your server hostname / IP address on port 9000 and create your admin account for Portainer-CE"
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    # Install Portainer Agent
    if [[ "$PORT" == "2" ]]; then
        echo "1. Preparing to install Portainer Agent"
        echo "2. Creating the folder structure for Portainer."
        echo "3. You can find Portainer-Agent files in ./docker/portainer"

        sudo docker volume create portainer_data
        mkdir -p docker/portainer
        cd docker/portainer
        curl https://raw.githubusercontent.com/jkocianICA/ica-it-compose/main/PortainerAgent_docker-compose.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
        echo ""
        
        # Start Portainer Agent container
        echo "Starting Portainer Agent..."
        echo ""
        sudo docker-compose up -d

        echo ""
        echo "    From Portainer or Portainer-CE add this Agent instance via the 'Endpoints' option in the left menu."
        echo "       ####     Use the IP address of this server and port 9001"
        echo ""
        echo ""
        echo ""
        sleep 3s
        cd
    fi

    exit 1

}

echo ""
echo ""
echo "This wizard is intended to perform basic post-install configuration after a VM is cloned or newly created."
echo "Please start by confirming the OS you are working on."
echo ""
echo ""
echo "From some basic information on your system, you appear to be running: "
echo "--  OS Name          " $(lsb_release -i)
echo "--  Description      " $(lsb_release -d)
echo "--  OS Version       " $(lsb_release -r)
echo "--  Code Name        " $(lsb_release -c)
echo ""
echo "------------------------------------------------"
echo ""

PS3="Please select the number for your OS / distro: "
select _ in \
    "CentOS 7 / 8 / Fedora" \
    "Debian 10 / 11" \
    "Ubuntu 18.04" \
    "Ubuntu 20.04 / 21.04 / 22.04" \
    "Arch Linux" \
    "Open Suse"\
    "End this Installer"
do
  case $REPLY in
    1) gatherInput ;;
    2) gatherInput ;;
    3) gatherInput ;;
    4) gatherInput ;;
    5) gatherInput ;;
    6) gatherInput ;;
    7) exit ;;
    *) echo "Invalid selection, please try again..." ;;
  esac
done
