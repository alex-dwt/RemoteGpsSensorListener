#! /bin/bash
# This file is part of the RemoteGpsSensorListener package.
# (c) Alexander Lukashevich <aleksandr.dwt@gmail.com>
# For the full copyright and license information, please view the LICENSE file that was distributed with this source code.

MACHINE_ARCH=$(uname -m | cut -c1-3 | tr '[:lower:]' '[:upper:]')
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DOCKER_ARM_IMAGE=sdhibit/rpi-raspbian
DOCKER_X86_IMAGE=ubuntu

NEW_LINE=$'\n'

###################################
######### Program Entry Point #######
#################################
function main {
    if [ "$MACHINE_ARCH" != "ARM" ] && [ "$MACHINE_ARCH" != "X86" ]; then
        echo "This program can work only at X86 or ARM machine. Abort!"
        exit 1
    fi

    case "$1" in
        "build")
            build
            ;;
        "start")
            if [[ $2 =~ ^-?[0-9]+$ ]]; then
                start $2
            else
                echo 'Specify the port for listening please!'
                exit 1
            fi
            ;;
        *)
        echo "Wrong command. Available commands are:$NEW_LINE \
- build$NEW_LINE \
- start X, where 'X' is port which the service should listen to"
        exit 1
        ;;
    esac
}

###########################
#### Create docker image  ###
#########################
function build {
    echo 'Started creating image...'
    docker build -t alex_dwt/remote-gps-sensor-listener -f Dockerfile-$MACHINE_ARCH $WORK_DIR
    echo 'Done!'
}

###########################
#### Start docker container ###
#########################
function start {
    if [ "$(docker images | egrep -c 'alex_dwt/remote-gps-sensor-listener')" -eq 0 ]; then
        echo "Can not find docker image. You should run 'build' command at first!"
        exit 1
    fi

    docker rm -f alex-dwt-remote-gps-sensor-listener >/dev/null 2>&1

    docker run -d \
        -p $1:80 \
        $(find /dev/ 2>/dev/null | egrep "/dev/ttyACM*|/dev/bus*" | xargs -I {} printf "--device={}:{} ") \
        --name alex-dwt-remote-gps-sensor-listener \
        alex_dwt/remote-gps-sensor-listener >/dev/null 2>&1

    if [ $? -ne 0 ]
    then
      echo 'Fail!'
    else
      echo 'Success!'
    fi
}

# execute
main "$@"