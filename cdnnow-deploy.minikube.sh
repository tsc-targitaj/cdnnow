#!/bin/bash

echo on

# Variables
PROJECT_NAME="cdnnow"
#PROJECT_ROOT="/home/`whoami`/Projects/$PROJECT_NAME"
PROJECT_ROOT="./"
PROJECT_APP1="nginx"
PROJECT_APP2="php"
PROJECT_CODE="app"
PROJECT_TEMPLATES="templates"
PROJECT_AUTOTEST="test"
BUILD_TAG=""
BUILD_YAML="cdnnow-build.yaml"
AUTOTEST_YAML="cdnnow-autotest.yaml"
DEPLOY_TEST_YAML=""
DEPLOY_PROD_YAML=""
START_PROD_YAML="cdnnow-start.production.yaml"
IMAGES_REPO=""
STAGE_ENTRY=""
PROD_ENTRY=""
NOW=`date +"%Y-%m-%d_%H-%M-%S_%Z"`

# Functions
function prepare_kube
{
    echo
    echo -e "\033[37;1;42m --- Check/install kubectl utility. Need sudo for install. \033[0m"
    kubectl help 2>&1 >/dev/null || \
    (curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && sudo install kubectl /usr/local/bin/ \
    ; rm kubectl)
    kubectl help 2>&1 >/dev/null && (echo; echo " --- kubectl ready")
    echo
    echo -e "\033[37;1;42m --- Check/install minikube utility. Need sudo for install. \033[0m"
    minikube help 2>&1 >/dev/null || \
    (curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && chmod +x minikube \
    && sudo install minikube /usr/local/bin/ \
    ; rm minikube)
    minikube help 2>&1 >/dev/null && (echo; echo " --- minikube ready")
}

function start_kube
{
    echo
    echo -e "\033[37;1;42m --- Check/start minikube processes. \033[0m"
    minikube status | grep -e host | grep -e Running 2>&1 >/dev/null || minikube start
    minikube status | grep -e host | grep -e Running 2>&1 >/dev/null && (echo; echo " --- minikube running")
}

function prepare_app
{
    echo
    echo -e "\033[37;1;42m --- Preparing files. \033[0m"
    echo $PROJECT_ROOT
    rsync -avvP $PROJECT_ROOT/templates/etc/nginx/conf.d/*conf $PROJECT_ROOT/nginx/
    rsync -avvP $PROJECT_ROOT/app/ $PROJECT_ROOT/nginx/www/
    rsync -avvP $PROJECT_ROOT/app/*php $PROJECT_ROOT/php/www/
}


function build
{
    echo
    echo -e "\033[37;1;42m --- Starting build stage. \033[0m"
    export TAG="$NOW"
    docker-compose -f $1 build
}

function autotest
{
    echo
    echo -e "\033[37;1;42m --- Starting autotest stage. \033[0m"
    docker-compose -f $1 -f $2 up --abort-on-container-exit --exit-code-from $3
}

function saveimage
{
    echo
    echo -e "\033[37;1;42m --- Saving image to repo. \033[0m"
}

function cleanup
{
    echo
    echo -e "\033[37;1;42m --- Starting cleanup stage. \033[0m"
    echo
    echo " --- Removing containers"
    docker rm $(docker ps -a -q --filter="name=$PROJECT_NAME*") 2>/dev/null
    echo
    echo " --- Removing images"
    docker rmi $(docker images "$PROJECT_NAME*" -a -q) --force 2>/dev/null
    rm -rf $PROJECT_ROOT/nginx/www/*
    rm -rf $PROJECT_ROOT/nginx/*conf
    rm -rf $PROJECT_ROOT/php/www/*
}

function error
{
    # Error worker
    echo
    echo -e "\033[37;1;42m --- SOMTHING WRONG!!! \033[0m"
    echo "Cleaning up"
    cleanup
    finish 1
}

function finish
{
    # Exit with code
    echo
    echo -e "\033[37;1;42m --- Finishing with code $1 \033[0m"
    echo -e "\033[37;1;42m --- Bye \033[0m"
    exit $1
}

function start_console
{
    # Start applications
    echo
    echo -e "\033[37;1;42m --- Starting applications in console mode. \033[0m"
    docker-compose -f $1 up
}

# Start here
clear
echo -e "\033[37;1;42m --- Starting deploy script. \033[0m"
echo
echo "Now is $NOW"
echo "Project name is $PROJECT_NAME"
echo "Project root is $PROJECT_ROOT"
echo "Project app1 here $PROJECT_ROOT/$PROJECT_APP1"
echo "Project app2 here $PROJECT_ROOT/$PROJECT_APP2"
echo "Project code here $PROJECT_ROOT/$PROJECT_CODE"
echo "Project autotest here $PROJECT_ROOT/$PROJECT_AUTOTEST"

# Preare
#prepare_app || error
prepare_kube
start_kube

# Build stage
#build $BUILD_YAML || error

# Autotest stage
#autotest $BUILD_YAML $AUTOTEST_YAML $PROJECT_AUTOTEST || error

# Saving images to repository
#saveimage

# Deploy to stage

# Deploy to prod

# Start application here
#start_console $START_PROD_YAML || error

# Cleanup stage
cleanup

# Finishin
#finish 0
