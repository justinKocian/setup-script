#!/bin/bash

installApps()
{
    # Green text
    C="\e[1;32m"
    EC="\e[0m"

    clear
    OS="$REPLY" ## <-- This $REPLY is about OS Selection
    echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
    echo "│ *                                                                                           * │"
    echo -e "│                                    ${C}  Docker Setup  ${EC}                                           │"
    echo "│                                                                                               │"
    echo "│    Before initial setup has been completed, we'll install Docker and any containers that      │"
    echo "│    would be useful for this instance.                                                         │"
    echo "│                                                                                               │"
    echo "│    Please note: Docker must be installed if you wish to install any containers. Portainer     │"
    echo "│    is installed using the Docker CLI, but docker compose is needed in order to install        │"
    echo "│    NGinX Proxy Manager                                                                        │"
    echo "│                                                                                               │"
    echo "│    Please select 'y' for each item you would like to install.                                 │"
    echo "│                                                                                               │"
    echo "│ *                                                                                           * │"
    echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"

    
    # Checking Docker and Docker Compose
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    ISCOMP=$( (docker-compose -v ) 2>&1 )

    #### Try to check whether docker is installed and running - don't prompt if it is
    if [[ "$ISACT" != "active" ]]; then
        read -rp "Docker-CE (y/n): " DOCK
    else
        echo "Docker appears to be installed and running."
        echo ""
        echo ""
    fi

    if [[ "$ISCOMP" == *"command not found"* ]]; then
        read -rp "Docker-Compose (y/n): " DCOMP
    else
        echo "Docker-compose appears to be installed."
        echo ""
        echo ""
    fi

    read -rp "NGinX Proxy Manager (y/n): " NPM
    read -rp "Uptime-Kuma (y/n): " UPTMK
    read -rp "Focalboard (y/n): " FOCAL
    read -rp "Portainer-CE (y/n): " PTAIN

    if [[ "$PTAIN" == [yY] ]]; then
        echo ""
        echo ""
        PS3="Please choose either Portainer-CE or just Portainer Agent: "
        select _ in \
        " Full Portainer-CE (Web GUI for Docker, Swarm, and Kubernetes)" \
        " Portainer Agent - Remote Agent to Connect from Portainer-CE" \
        " Nevermind -- I don't need Portainer after all."
        do
            PORT="$REPLY"
            case $REPLY in
                1) startInstall ;;
                2) startInstall ;;
                3) startInstall ;;
                *) echo "Invalid selection, please try again..." ;;
            esac
        done
    fi
    
    startInstall
}

startInstall() 
{
    # Green text
    C="\e[1;32m"
    EC="\e[0m"

    clear
    
    echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
    echo "│ *                                                                                           * │"
    echo -e "│                                 ${C}  Getting Things Ready  ${EC}                                      │"
    echo "│                                                                                               │"
    echo "│   Before installing the selected containers, we will run updates and install dependencies.    │"
    echo "│                                                                                               │"
    echo "│   The dependencies installed automatically are as follows:                                    │"
    echo "│       1. wget:      Makes it possible to download files and interact with REST APIs.          │"
    echo "│                                                                                               │"
    echo "│       2. cURL:      A computer software project providing a library and command-line tool     │"
    echo "│                     for transferring data using various network protocols.                    │"
    echo "│                                                                                               │"
    echo "│       3. net-tools: Useful networking utilities (e.g. hostname, ifconfig, route.)             │"
    echo "│                                                                                               │"
    echo "│       4. git:       Tool used to interact with Git, a version control system.                 │"
    echo "│ *                                                                                           * │"
    echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
    echo ""
    sleep 3s


    # ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
    # │ *                              Install for Debian / Ubuntu                                  * │
    # ╰───────────────────────────────────────────────────────────────────────────────────────────────╯

    if [[ "$OS" != "1" ]]; then
        echo "1. Installing System Updates... this may take a while...be patient."
        (sudo apt update && sudo apt upgrade -y) >> ~/config-wizard.log 2>&1 &
        spinner () {
            local SP_WIDTH="${3:-1.1}"
            local SP_DELAY="${4:-.2}"
            local SP_STRING=${2:-'-\|/'}
            local SP_COLOR=0
            tput civis
            while [ -d /proc/$1 ]; do
                printf "\e[38;5;$((RANDOM%257))m %${SP_WIDTH}s\r\e[0m" "$SP_STRING"
                sleep $SP_DELAY
                SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}
            done
            tput cnorm
        }

        sleep 7 &
        spinner "$!"

        echo "2. Installing Prerequisite Packages..."
        sleep 2s

        (sudo apt install curl wget git net-tools -y) >> ~/config-wizard.log 2>&1 &
        spinner () {
            local SP_WIDTH="${3:-1.1}"
            local SP_DELAY="${4:-.2}"
            local SP_STRING=${2:-'-\|/'}
            local SP_COLOR=0
            tput civis
            while [ -d /proc/$1 ]; do
                printf "\e[38;5;$((RANDOM%257))m %${SP_WIDTH}s\r\e[0m" "$SP_STRING"
                sleep $SP_DELAY
                SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}
            done
            tput cnorm
        }

        sleep 7 &
        spinner "$!"

        echo "3. Installing Docker-CE (Community Edition)..."
        sleep 2s

        (curl -fsSL https://get.docker.com | sh) >> ~/config-wizard.log 2>&1 &

        spinner () {
            local SP_WIDTH="${3:-1.1}"
            local SP_DELAY="${4:-.2}"
            local SP_STRING=${2:-'-\|/'}
            local SP_COLOR=0
            tput civis
            while [ -d /proc/$1 ]; do
                printf "\e[38;5;$((RANDOM%257))m %${SP_WIDTH}s\r\e[0m" "$SP_STRING"
                sleep $SP_DELAY
                SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}
            done
            tput cnorm
        }

        sleep 7 &
        spinner "$!"

        echo "      - docker-ce version is now:"
        DOCKERV=$(docker -v)
        echo "          "${DOCKERV}
        sleep 3s

        if [[ "$OS" == 2 ]]; then
            echo "    5. Starting Docker Service"
            (sudo systemctl docker start) >> ~/config-wizard.log 2>&1 &
            spinner () {
                local SP_WIDTH="${3:-1.1}"
                local SP_DELAY="${4:-.2}"
                local SP_STRING=${2:-'-\|/'}
                local SP_COLOR=0
                tput civis
                while [ -d /proc/$1 ]; do
                    printf "\e[38;5;$((RANDOM%257))m %${SP_WIDTH}s\r\e[0m" "$SP_STRING"
                    sleep $SP_DELAY
                    SP_STRING=${SP_STRING#"${SP_STRING%?}"}${SP_STRING%?}
                done
                tput cnorm
            }

            sleep 7 &
            spinner "$!"
        fi

    fi
        
    # ╭───────────────────────────────────────────────────────────────────────────╮
    # │ *                      Install for CentOS 7 or 8                        * │
    # ╰───────────────────────────────────────────────────────────────────────────╯
    if [[ "$OS" == "1" ]]; then
        if [[ "$DOCK" == [yY] ]]; then
            echo "    1. Updating System Packages..."
            sudo yum check-update >> ~/config-wizard.log 2>&1

            echo "    2. Installing Prerequisite Packages..."
            sudo dnf install git curl wget -y >> ~/config-wizard.log 2>&1

            echo "    3. Installing Docker-CE (Community Edition)..."

            sleep 2s
            (curl -fsSL https://get.docker.com/ | sh) >> ~/config-wizard.log 2>&1

            echo "    4. Starting the Docker Service..."

            sleep 2s


            sudo systemctl start docker >> ~/config-wizard.log 2>&1

            echo "    5. Enabling the Docker Service..."
            sleep 2s

            sudo systemctl enable docker >> ~/config-wizard.log 2>&1

            echo "      - docker version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
        fi
    fi

    # ╭───────────────────────────────────────────────────────────────────────────╮
    # │ *                     Install for Arch Linux                            * │
    # ╰───────────────────────────────────────────────────────────────────────────╯

    if [[ "$OS" == "5" ]]; then
        read -rp "Do you want to install system updates prior to installing Docker-CE? (y/n): " UPDARCH
        if [[ "UPDARCH" == [yY] ]]; then
            echo "    1. Installing System Updates... this may take a while...be patient."
            (sudo pacman -Syu) > ~/config-wizard.log 2>&1 &
            ## Show a spinner for activity progress
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
        else
            echo "    1. Skipping system update..."
            sleep 2s
        fi

        echo "    2. Installing Prerequisit Packages..."
        sudo pacman -Sy git curl wget >> ~/config-wizard.log 2>&1

        echo "    3. Installing Docker-CE (Community Edition)..."
            sleep 2s

            curl -fsSL https://get.docker.com | sh >> ~/config-wizard.log 2>&1

            echo "    - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
    fi

    if [[ "$DOCK" == [yY] ]]; then
        # add current user to docker group so sudo isn't needed
        echo ""
        echo "  - Attempting to add the currently logged in user to the docker group..."

        sleep 2s
        sudo usermod -aG docker "${USER}" >> ~/config-wizard.log 2>&1
        echo "  - You'll need to log out and back in to finalize the addition of your user to the docker group."
        echo ""
        echo ""
        sleep 3s
    fi

    if [[ "$DCOMP" = [yY] ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                              ${C}  Installing Docker-Compose  ${EC}                                * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"

        # install docker-compose
        echo ""
        echo "    1. Installing Docker-Compose..."
        echo ""
        echo ""
        sleep 2s

        # ╭───────────────────────────────────────────────────────────────────────────╮
        # │ *                      Install for Debian / Ubuntu                      * │
        # ╰───────────────────────────────────────────────────────────────────────────╯
        
        if [[ "$OS" == "2" || "$OS" == "3" || "$OS" == "4" ]]; then
            sudo apt install docker-compose -y >> ~/config-wizard.log 2>&1
        fi

        # ╭───────────────────────────────────────────────────────────────────────────╮
        # │ *                      Install for CentOS 7 or 8                        * │
        # ╰───────────────────────────────────────────────────────────────────────────╯

        if [[ "$OS" == "1" ]]; then
            sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> ~/config-wizard.log 2>&1

            sudo chmod +x /usr/local/bin/docker-compose >> ~/config-wizard.log 2>&1
        fi

        # ╭───────────────────────────────────────────────────────────────────────────╮
        # │ *                     Install for Arch Linux                            * │
        # ╰───────────────────────────────────────────────────────────────────────────╯

        if [[ "$OS" == "5" ]]; then
            sudo pacman -Sy >> ~/config-wizard.log 2>&1
            sudo pacman -Sy docker-compose > ~/config-wizard.log 2>&1
        fi

        echo ""

        echo "      - Docker Compose Version is now: " 
        DOCKCOMPV=$(docker-compose --version)
        echo "        "${DOCKCOMPV}
        echo ""
        echo ""
        sleep 3s
    fi

    # ╭───────────────────────────────────────────────────────────────────────────╮
    # │ *                Test if Docker service is running                      * │
    # ╰───────────────────────────────────────────────────────────────────────────╯
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if [[ "$ISACt" != "active" ]]; then
        echo "Giving the Docker service time to start..."
        while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
            sudo systemctl start docker >> ~/config-wizard.log 2>&1
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

    if [[ "$NPM" == [yY] ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                              ${C}  Installing NGINX Proxy Manager  ${EC}                           * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"

    
        # pull an nginx proxy manager docker-compose file from github
        echo "    1. Pulling a default NGinX Proxy Manager docker-compose.yml file."

        cd ~
        mkdir -p docker/nginx-proxy-manager
        cd docker/nginx-proxy-manager

        curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose.nginx_proxy_manager.yml -o docker-compose.yml >> ~/config-wizard.log 2>&1

        echo "    2. Running the docker-compose.yml to install and start NGinX Proxy Manager"
        echo ""
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker-compose up -d
        fi

        if [[ "$OS" != "1" ]]; then
          sudo docker-compose up -d
        fi

        echo ""
        echo ""
        echo "    Navigate to your server hostname / IP address on port 81 to setup"
        echo "    NGinX Proxy Manager admin account."
        echo ""
        echo "    The default login credentials for NGinX Proxy Manager are:"
        echo "        username: admin@example.com"
        echo "        password: changeme"

        echo ""       
        sleep 3s
    fi

    if [[ "$PORT" == "1" ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                              ${C}  Installing Portainer CE  ${EC}                                  * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
        echo ""
        echo "    1. Preparing to Install Portainer-CE"
        echo ""
        echo ""

        cd ~
        cd docker

        sudo docker volume create portainer_data
        sudo docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
        echo ""
        echo ""
        echo "    Navigate to your server hostname / IP address on port 9000 and create your admin account for Portainer-CE"

        echo ""
        echo ""
        echo ""
        sleep 3s
    fi

    if [[ "$PORT" == "2" ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                              ${C}  Installing Portainer Agent  ${EC}                               * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
        echo ""
        echo "    1. Preparing to install Portainer Agent"
        echo ""
        
        cd ~
        cd docker

        sudo docker volume create portainer_data
        sudo docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes portainer/agent
        echo ""
        echo ""
        echo "    From Portainer or Portainer-CE add this Agent instance via the 'Endpoints' option in the left menu."
        echo "       ####     Use the IP address of this server and port 9001"
        echo ""
        echo ""
        echo ""
        sleep 3s
    fi

    if [[ "$UPTMK" == [yY] ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                              ${C}  Installing Uptime-Kuma  ${EC}                                   * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
    
        # pull a simple uptime-kuma docker-compose file from github
        echo "    1. Pulling a simple Uptime-Kuma docker-compose.yml file."
        echo ""
        
        cd ~
        cd docker
        mkdir -p docker/uptime-kuma
        cd docker/uptime-kuma

        curl https://raw.githubusercontent.com/louislam/uptime-kuma/master/docker/docker-compose.yml -o docker-compose.yml >> ~/config-wizard.log 2>&1

        echo "    2. Running the docker-compose.yml to install and start Uptime-Kuma"
        echo ""
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker-compose up -d
        fi

        if [[ "$OS" != "1" ]]; then
          sudo docker-compose up -d
        fi

        echo ""
        echo ""
        echo "Navigate to your server hostname / IP address on port 3001 to setup"
        echo ""
        echo ""       
        sleep 3s
    fi

        if [[ "$FOCAL" == [yY] ]]; then
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo -e "│ *                                ${C}  Installing Focalboard  ${EC}                                  * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
    
        # pull a simple uptime-kuma docker-compose file from github
        echo "    1. Pulling a simple Focalboard docker-compose.yml file."

        cd ~
        cd docker
        mkdir -p docker/uptime-kuma
        cd docker/uptime-kuma

        curl https://raw.githubusercontent.com/mattermost/focalboard/main/docker/docker-compose.yml -o docker-compose.yml >> ~/config-wizard.log 2>&1

        echo "    2. Running the docker-compose.yml to install and start Focalboard"
        echo ""
        echo ""

        if [[ "$OS" == "1" ]]; then
          docker compose up -d
        fi

        if [[ "$OS" != "1" ]]; then
          sudo docker compose up -d
        fi

        echo ""
        echo ""
        echo "Navigate to your server hostname / IP address on port 80 to setup"
        echo ""
        echo ""       
        sleep 3s
    fi


    exit 1
}

# ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
# │ *                                     Introduction                                          * │
# ╰───────────────────────────────────────────────────────────────────────────────────────────────╯
    
    # Text options
    C="\e[1;32m" # Green text, bold
    CU="\e[4;32m" # Green text, underlined
    EC="\e[0m"

echo ""
echo ""
echo ""

clear

echo "╭────────────────────────────────────────────────────────────────────────────────────────────────╮"
echo -e "│ *         ${C}         ___             __ _         __    __ _                  _       ${EC}         * │"
echo -e "│           ${C}        / __\___  _ __  / _(_) __ _  / / /\ \ (_)______ _ _ __ __| |      ${EC}           │"
echo -e "│           ${C}       / /  / _ \| '_ \| |_| |/ _' | \ \/  \/ / |_  / _' | '__/ _' |      ${EC}           │"
echo -e "│           ${C}      / /__| (_) | | | |  _| | (_| |  \  /\  /| |/ / (_| | | | (_| |      ${EC}           │"
echo -e "│           ${C}      \____/\___/|_| |_|_| |_|\__, |   \/  \/ |_/___\__,_|_|  \__,_|      ${EC}           │"
echo -e "│           ${C}                              |___/                                       ${EC}           │"
echo "│    ╔──────────────────────────────────────────────────────────────────────────────────────╗    │"
echo "│    │             Adapted by Justin Kocian from work done by Brian McGonagill              │    │"
echo "│    ╚──────────────────────────────────────────────────────────────────────────────────────╝    │"
echo "│                                                                                                │"
echo "│    This wizard performs initial Docker-related configurations and presents options to          │"
echo "│    automatically install commonly used containers. Important note: Please run this script      │"
echo "|    from the user root directory.                                                               |"
echo "│                                                                                                │"
echo "│ *                                                                                            * │"
echo "╰────────────────────────────────────────────────────────────────────────────────────────────────╯"
echo ""
echo " According to a quick check of your system info, you appear to be running:                       "
echo ""
echo "       --  OpSys        " $(lsb_release -i)
echo "       --  Desc:        " $(lsb_release -d)
echo "       --  OSVer        " $(lsb_release -r)
echo "       --  CdNme        " $(lsb_release -c)
echo ""
PS3="To be sure, please select the number for your OS / distro: "
select _ in \
    "CentOS 7 / 8 / Fedora" \
    "Debian 10 / 11" \
    "Ubuntu 18.04" \
    "Ubuntu 20.04 / 21.04 / 22.04" \
    "Arch Linux" \
    "End this Installer"
do
  case $REPLY in
    1) installApps ;;
    2) installApps ;;
    3) installApps ;;
    4) installApps ;;
    5) installApps ;;
    6) exit ;;
    *) echo "Invalid selection, please try again..." ;;
  esac
done