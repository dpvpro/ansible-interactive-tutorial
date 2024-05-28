#!/bin/bash
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NOF_HOSTS=3
NETWORK_NAME="ansible.tutorial"
WORKSPACE="${BASEDIR}/ansible-sline-roles"
TUTORIALS_FOLDER="${BASEDIR}/tutorials"

HOSTPORT_BASE=${HOSTPORT_BASE:-42726}
# Extra ports per host to expose. Should contain $NOF_HOSTS variables
EXTRA_PORTS=( "8080" "30000" "443" )
# Port Mappin
# +-----------+----------------+-------------------+
# | Container | Container Port |     Host Port     |
# +-----------+----------------+-------------------+
# |   host0   |       80       | $HOSTPORT_BASE    |
# +-----------+----------------+-------------------+
# |   host1   |       80       | $HOSTPORT_BASE+1  |
# +-----------+----------------+-------------------+
# |   host2   |       80       | $HOSTPORT_BASE+2  |
# +-----------+----------------+-------------------+
# |   host0   | EXTRA_PORTS[0] | $HOSTPORT_BASE+3  |
# +-----------+----------------+-------------------+
# |   host1   | EXTRA_PORTS[1] | $HOSTPORT_BASE+4  |
# +-----------+----------------+-------------------+
# |   host2   | EXTRA_PORTS[2] | $HOSTPORT_BASE+5  |
# +-----------+----------------+-------------------+

DOCKER_IMAGETAG=${DOCKER_IMAGETAG:-1.0}
# DOCKER_HOST_IMAGE="turkenh/ubuntu-1604-ansible-docker-host:${DOCKER_IMAGETAG}"
# TUTORIAL_IMAGE="turkenh/ansible-tutorial:${DOCKER_IMAGETAG}"

DOCKER_HOST_IMAGE="dp/ubuntu-1604-ansible-docker-host:${DOCKER_IMAGETAG}"
TUTORIAL_IMAGE="dp/ubuntu-wks:${DOCKER_IMAGETAG}"

# DOCKER_HOST_IMAGE="dp/ubuntu14.04:${DOCKER_IMAGETAG}"
# TUTORIAL_IMAGE="turkenh/ansible-tutorial:${DOCKER_IMAGETAG}"



function help() {
    echo -ne "-h, --help              prints this help message
-r, --remove            remove created containers and network 
-t, --test              run lesson tests
"
}
function doesNetworkExist() {
    return $(docker network inspect $1 >/dev/null 2>&1)
}

function removeNetworkIfExists() {
    doesNetworkExist $1 && echo "removing network $1" && docker network rm $1 >/dev/null
}

function doesContainerExist() {
    return $(docker inspect $1 >/dev/null 2>&1)
}

function killContainerIfExists() {
    doesContainerExist $1 && echo "killing/removing container $1" && { docker kill $1 >/dev/null 2>&1; docker rm $1 >/dev/null 2>&1; };
}

function runHostContainer() {
    local name=$1
    local image=$2
    local port1=$(($HOSTPORT_BASE + $3))
    local port2=$(($HOSTPORT_BASE + $3 + $NOF_HOSTS))
    # echo "starting container ${name}: mapping hostport $port1 -> container port 80 && hostport $port2 -> container port ${EXTRA_PORTS[$3]}"
    # docker run -t -d -p $port1:80 -p $port2:${EXTRA_PORTS[$3]} --net ${NETWORK_NAME} --name="${name}" "${image}" >/dev/null
    echo "starting container ${name}"
    docker run -t -d --net ${NETWORK_NAME} --name="${name}" "${image}" >/dev/null
    if [ $? -ne 0 ]; then
        echo "Could not start host container. Exiting!"
        exit 1
    fi
    # inject own key
    # docker exec -i ${name} sh -c 'echo -e "\n" >> /root/.ssh/authorized_keys'
    # cat ~/.ssh/id_rsa.pub | docker exec -i ${name} sh -c 'cat >> /root/.ssh/authorized_keys'
}

function runTutorialContainer() {
    local entrypoint=""
    local args=""
    if [ -n "${TEST}" ]; then
        entrypoint="--entrypoint nutsh"
        args="test /tutorials ${LESSON_NAME}"  
    fi
    killContainerIfExists ansible.tutorial > /dev/null
    echo "starting container ansible.tutorial"
    # docker run -it -v "${WORKSPACE}":/root/workspace -v "${TUTORIALS_FOLDER}":/tutorials --net ${NETWORK_NAME} \
    #   --env HOSTPORT_BASE=$HOSTPORT_BASE \
    #   ${entrypoint} --name="ansible.tutorial" "${TUTORIAL_IMAGE}" ${args}
    docker run -it -v "${WORKSPACE}":/root/workspace -v "${TUTORIALS_FOLDER}":/tutorials --net ${NETWORK_NAME} \
      --env HOSTPORT_BASE=$HOSTPORT_BASE \
      --name="ansible.tutorial" "${TUTORIAL_IMAGE}"
    return $?
}

function remove () {
    for ((i = 0; i < $NOF_HOSTS; i++)); do
       killContainerIfExists host$i.example.org
    done
    removeNetworkIfExists ${NETWORK_NAME}
} 

function setupFiles() {
    # step-01/02
    local step_01_hosts_file="${BASEDIR}/tutorials/files/step-1-2/hosts"
    rm -f "${step_01_hosts_file}"
    for ((i = 0; i < $NOF_HOSTS; i++)); do
        ip=$(docker network inspect --format="{{range \$id, \$container := .Containers}}{{if eq \$container.Name \"host$i.example.org\"}}{{\$container.IPv4Address}} {{end}}{{end}}" ${NETWORK_NAME} | cut -d/ -f1)
        echo "host$i.example.org ansible_host=host$i.example.org ansible_user=root" >> "${step_01_hosts_file}" 
    done

    # generate custom hosts file
    echo "[sline-test]" > "${WORKSPACE}/ansible_hosts"
    cat "${step_01_hosts_file}" | tee -a "${WORKSPACE}/ansible_hosts"
    
}
function init () {
    mkdir -p "${WORKSPACE}"
    doesNetworkExist "${NETWORK_NAME}" || { echo "creating network ${NETWORK_NAME}" && docker network create "${NETWORK_NAME}" >/dev/null; }
    for ((i = 0; i < $NOF_HOSTS; i++)); do
       doesContainerExist host$i.example.org || runHostContainer host$i.example.org ${DOCKER_HOST_IMAGE} $i
    done
    setupFiles
    runTutorialContainer
    exit $?
}

###
MODE="init"
TEST=""
for i in "$@"; do
case $i in
    -r|--remove)
    MODE="remove"
    shift # past argument=value
    ;;
    -t|--test)
    TEST="yes"
    shift # past argument=value
    ;;
    -h|--help)
    help
    exit 0
    shift # past argument=value
    ;;
    *)
    echo "Unknow argument ${i#*=}"
    exit 1
esac
done

if [ "${MODE}" == "remove" ]; then
    remove
elif [ "${MODE}" == "init" ]; then
    init
fi
exit 0