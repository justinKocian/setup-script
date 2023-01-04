#!/usr/bin/bash
# Written by Justin Kocian
#
# This script is used to perform initial configuration for new servers that will be running Docker.
# 
# Before running this script:
# 1. Add $USER to sudo group:
#     sudo su
#     usermod -aG sudo ${USER}
#     exit
#     cd ~
# 
# 2. Create directories:
#   - scripts
#   - logs
# The docker directory will be added as part of the script
#
#----------------------------------------------------------------------------------------------------------------------------
#
# ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
# │ *                       Docker and Portainer Installation Prompts                           * │
# ╰───────────────────────────────────────────────────────────────────────────────────────────────╯
    installApps()
    {
        # TEXT COLOR OPTIONS
        #   Wrap text in these variables to add color formatting.
        #   ${C}Example${EC}
        
        C="\e[1;32m"
        EC="\e[0m"

        clear
        OS="$REPLY" # This is the reply to the OS confirmation at the start
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo "│ *                                                           ##         .                    * │"
        echo "│                                                        ## ## ##        ==                     │"
        echo "│      Docker & Portainer                            ## ## ## ## ##    ===                      │"
        echo "│      Installation                              /‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\___/ ===                   │"
        echo "│      Prompts                              ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~             │"
        echo "│                                                \______ o           __/                        │"
        echo "│                                                    \    \         __/                         │"
        echo "│                                                     \____\_______/                            │"
        echo "│ *                                                                                           * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
        
        # Add currently logged in user to sudo group (leaving out for now)
        # sudo su
        # usermod -aG ${USER}
        # exit
        # cd ~

        # Variables used to check if Docker or Docker Compose are installed
        ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
        ISCOMP=$( (docker-compose -v ) 2>&1 )

        # Checking to see if Docker and Docker Compose are installed
        # Will not prompt to download if already installed
        if [[ "$ISACT" != "active" ]]; then
            read -rp "Install Docker? (y/n): " DOCK
        else
            echo "Docker appears to be installed and running."
            echo ""
            echo ""
        fi

        if [[ "$ISCOMP" == *"command not found"* ]]; then
            read -rp "Install Docker Compose? (y/n): " DCOMP
        else
            echo "Docker-compose appears to be installed."
            echo ""
            echo ""
        fi

        # Portainer
        read -rp "Install Portainer? (y/n): " PTAIN

        # Determine which type of Portainer installation is needed
        if [[ "$PTAIN" == [yY] ]]; then
            echo ""
            echo ""
            PS3="Is this a Priamary Portainer installation, or a Portainer Agent installation?: "
            select _ in \
                " Primary Portainer - Web GUI for Docker, Swarm, and Kubernetes" \
                " Portainer Agent - Remote Agent accessed from a Primary Portainer server" \
                " Nevermind - I don't need Portainer after all."
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

#
#
# ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
# │ *                                Installation and Updates                                   * │
# ╰───────────────────────────────────────────────────────────────────────────────────────────────╯
    startInstall() 
    {
        # Green text
        C="\e[1;32m"
        EC="\e[0m"

        clear
        
        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo "│ *                                                                                           * │"
        echo "│                              Updates and Docker Installation                                  │"
        echo "│ *                                                                                           * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
        echo ""
        sleep 3s


        # ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
        # │ *                              Install for Debian / Ubuntu                                  * │
        # ╰───────────────────────────────────────────────────────────────────────────────────────────────╯
      
        ### Initial updates/upgrades
        if [[ "$OS" = "1" ]]; then
            echo "1. Installing system updates. This may take a while..."
            (sudo apt update && sudo apt upgrade -y) >> ~/logs/setup-script.log 2>&1 &
            ## Show spinner for progress
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
            spinner "$!" # <-- Process ID of the previously running command

        ### Installing dependencies/prerequisite packages
            echo "2. Installing Prerequisite Packages..."
            sleep 2s

            cd ~
            mkdir docker
            mkdir logs
            cd ~

            (sudo apt install curl wget git net-tools -y) >> ~/logs/setup-script.log 2>&1 &
            ## Show spinner for progress
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
            spinner "$!" # <-- Process ID of the previously running command

        ### Install Docker
            if [[ "$ISACT" != "active" ]]; then
                echo "3. Installing Docker Community Edition..."
                sleep 2s

                cd ~
                mkdir docker
                cd docker

                (curl -fsSL https://get.docker.com | sh) >> ~/logs/setup-script.log 2>&1 &
                ## Show spinner for progress
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
                spinner "$!" # <-- Process ID of the previously running command

                echo "Docker CE version is now:"
                DOCKERV=$(docker -v)
                echo "          "${DOCKERV}
                sleep 3s

            ### Start Docker service
                if [[ "$OS" == 1 ]]; then
                    echo "    - Starting Docker Service..."
                    sudo systemctl docker start >> ~/logs/setup-script.log.log 2>&1
                fi
            fi

        fi

        # if [[ "$DOCK" == [yY] ]]; then
        # ### Add current user to the docker group so sudo isn't needed
        #     echo "    - Attempting to add the currently logged in user to the docker group..."
        #     sudo usermod -aG docker "${USER}" >> ~/logs/setup-script.log 2>&1
        #     echo "    - You'll need to log out and back in to finalize the addition of your user to the docker group."
        #     sleep 3s
        # fi

        if [[ "$DCOMP" = [yY] ]]; then
            echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
            echo -e "│ *                              ${C}  Installing Docker-Compose  ${EC}                                * │"
            echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"

        ### Install Docker Compose
            echo "Installing Docker Compose..."
            sleep 2s

            # ╭───────────────────────────────────────────────────────────────────────────╮
            # │ *                      Install for Debian / Ubuntu                      * │
            # ╰───────────────────────────────────────────────────────────────────────────╯
            
            if [[ "$OS" == "1" || "$OS" == "2" || "$OS" == "3" ]]; then
                VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
                sudo curl -SL https://github.com/docker/compose/releases/download/$VERSION/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
                #sudo curl -L "https://github.com/docker/compose/releases/download/$(curl https://github.com/docker/compose/releases | grep -m1 '<a href="/docker/compose/releases/download/' | grep -o 'v[0-9:].[0-9].[0-9]')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

                sleep 2
                sudo chmod +x /usr/local/bin/docker-compose
            fi

        fi

        # ╭───────────────────────────────────────────────────────────────────────────╮
        # │ *                Test if Docker service is running                      * │
        # ╰───────────────────────────────────────────────────────────────────────────╯
        ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
        if [[ "$ISACt" != "active" ]]; then
            echo "Giving the Docker service time to start..."
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

        echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
        echo "│ *                                Creating Docker Network                                    * │"
        echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
        sudo docker network create my-main-net
        sleep 2s

        if [[ "$PORT" == "1" ]]; then
            echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
            echo -e "│ *                              ${C}  Installing Portainer CE  ${EC}                                  * │"
            echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
            echo ""
            echo "    1. Preparing to Install Portainer-CE"
            echo ""
            echo "    2. Creating the folder structure for Portainer."
            echo "    3. You can find Portainer-CE files in ./docker/portainer"

            #sudo docker volume create portainer_data >> ~/docker-script-install.log 2>&1
            mkdir -p docker/portainer/portainer_data
            cd docker/portainer
            curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
            echo ""

            sudo docker-compose up -d # <-- Run Portainer docker compose

            echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
            echo "│ *                                                                                           * │"
            echo "│    Portainer has now been installed. To access, navigate to...                                |"
            echo "│                                                                                               │"
            echo "│    https://[this_server's_ipaddress_or_hostname]:9000                                         │"
            echo "│ *                                                                                           * │"
            echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
            sleep 3s
        fi

        if [[ "$PORT" == "2" ]]; then
            echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
            echo -e "│ *                              ${C}  Installing Portainer Agent  ${EC}                               * │"
            echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
            echo ""
            echo "    1. Preparing to install Portainer Agent"
            echo "    2. Creating the folder structure for Portainer."
            echo "    3. You can find Portainer-Agent files in ./docker/portainer"

            sudo docker volume create portainer_data
            mkdir -p docker/portainer
            cd docker/portainer
            curl https://gitlab.com/bmcgonag/docker_installs/-/raw/main/docker_compose_portainer_ce_agent.yml -o docker-compose.yml >> ~/docker-script-install.log 2>&1
            echo ""
            
            sudo docker-compose up -d

            echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
            echo "│ *                                                                                           * │"
            echo "│    Add this agent to the Primary Portainer dashboard via the 'Endpoints' menu.                 |"
            echo "│                                                                                               │"
            echo "│    Use [this_server's_ipaddress]:9001                                         │"
            echo "│ *                                                                                           * │"
            echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
            sleep 3s
        fi

        echo "All docker applications have been added to the docker network my-main-app"
        echo ""
        echo "If you add more docker applications to this server, make sure to add them to the my-main-app network."
        echo "You can then use them by container name in NGinX Proxy Manager if so desired."

        exit 1
    }
#
#
# ╭───────────────────────────────────────────────────────────────────────────────────────────────╮
# │ *                                     Introduction                                          * │
# ╰───────────────────────────────────────────────────────────────────────────────────────────────╯
    # TEXT COLOR OPTIONS
    #   Wrap text in these variables to add color formatting.
    #   ${C}Example${EC}

    C="\e[1;32m" # Green text, bold
    CU="\e[4;32m" # Green text, underlined
    EC="\e[0m"

    # Skip a few lines and clear the screen to make room for the start page.
    echo ""
    echo ""
    echo ""

    clear

    echo "╭───────────────────────────────────────────────────────────────────────────────────────────────╮"
    echo "│ *                _____      __                 _____           _       __                   * │"
    echo "│                 / ___/___  / /___  ______     / ___/__________(_)___  / /_                    │"
    echo "│                 \__ \/ _ \/ __/ / / / __ \    \__ \/ ___/ ___/ / __ \/ __/                    │"
    echo "│                ___/ /  __/ /_/ /_/ / /_/ /   ___/ / /__/ /  / / /_/ / /_                      │"
    echo "│               /____/\___/\__/\__,_/ .___/   /____/\___/_/  /_/ .___/\__/                      │"
    echo "│                                  /_/                        /_/                               │"
    echo "│ *                                                                                           * │"
    echo "╰───────────────────────────────────────────────────────────────────────────────────────────────╯"
    # Confirm OS
    echo " According to a quick check of your system info, you appear to be running:                       "
    echo ""
    echo "       --  OpSys        " $(lsb_release -i)
    echo "       --  Desc:        " $(lsb_release -d)
    echo "       --  OSVer        " $(lsb_release -r)
    echo "       --  CdNme        " $(lsb_release -c)
    echo ""
    PS3="To be sure, please select the appropriate number for your OS / distribution: "
    select _ in \
        "Ubuntu 20.04 / 21.04 / 22.04" \
        "Debian 10 / 11" \
        "RasPiOS" \
        "End this Installer"
    do
    case $REPLY in
        1) installApps ;;
        2) installApps ;;
        3) installApps ;;
        4) exit ;;
        *) echo "Invalid selection, please try again." ;;
    esac
    done
