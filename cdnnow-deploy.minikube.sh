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
AUTOTEST_YAML="kube_cdnnow_dev_autotest.yaml"
DEPLOY_TEST_YAML=""
DEPLOY_PROD_YAML=""
START_PROD_YAML=""
IMAGES_REPO=""
STAGE_ENTRY=""
PROD_ENTRY=""
NOW=`date +"%Y-%m-%d_%H-%M-%S_%Z"`

# Functions
function pause
{
    echo
    read -p " --- Press ENTER to confirm and continue."
}

function prepare_minikube
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

function start_minikube
{
    echo
    echo -e "\033[37;1;42m --- Check/start minikube processes via docker. \033[0m"
    minikube status | grep -e host | grep -e Running 2>&1 >/dev/null || minikube start --driver docker
    minikube status | grep -e host | grep -e Running 2>&1 >/dev/null && (echo; echo " --- minikube running")
}

function prepare_env
{
    echo
    echo -e "\033[37;1;42m --- WARNING. Applying "minikube docker-env". \033[0m"
    pause
    eval $(minikube docker-env) || error
    echo
    echo " --- done"
}

function minikube_create_namespace
{
    echo
    echo -e "\033[37;1;42m --- Preparing environment. \033[0m"
    echo " --- Creating namespace "$PROJECT_NAME"-"$1"."
    kubectl get namespaces | grep "$PROJECT_NAME"-"$1" || kubectl create namespace "$PROJECT_NAME"-"$1"
    echo " --- Done."
}

function minikube_set_context
{
    echo " --- Seting namespace "$PROJECT_NAME"-"$1" as current."
    kubectl config set-context --current --namespace="$PROJECT_NAME"-"$1" || error
    echo " --- Done."
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

function minikube_build
{
    echo
    echo -e "\033[37;1;42m --- Starting building $PROJECT_NAME $1 $2. \033[0m"
    minikube image build $1 -t "$PROJECT_NAME"_$1:$2
}

function minikube_deploy
{
    echo
    echo -e "\033[37;1;42m --- Starting deploy $PROJECT_NAME $1. \033[0m"
    kubectl apply -f ./kube_$1/ || error
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
    echo -e "\033[37;1;42m --- AUTOTEST SUCCESS. \033[0m"
}

function minicube_start_console
{
    # Start applications
    echo
    echo -e "\033[37;1;42m --- Starting applications in console mode. \033[0m"
    minikube service cdnnow-nginx-$1-service -n "$PROJECT_NAME"-"$1"
}

function saveimage
{
    echo
    echo -e "\033[37;1;42m --- Saving image to repo. \033[0m"
}

function minikube_cleanup
{
    echo
    echo -e "\033[37;1;42m --- Starting cleanup $1. \033[0m"
    pause
    echo
    echo " --- Removing deployments."
    kubectl delete -n "$PROJECT_NAME"-"$1" deployment cdnnow-nginx-$1-deployment
    kubectl delete -n "$PROJECT_NAME"-"$1" deployment cdnnow-php-$1-deployment
    kubectl delete -n "$PROJECT_NAME"-"$1" service php
    kubectl delete -n "$PROJECT_NAME"-"$1" service cdnnow-nginx-$1-service
    echo
    echo " --- Removing containers."
    docker rm $(docker ps -a -q --filter="name=$PROJECT_NAME*") 2>/dev/null
    echo
    echo " --- Removing images."
    docker rmi $(docker images "$PROJECT_NAME*" -a -q) --force 2>/dev/null
}

function files_cleanup
{
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
    echo -e "\033[37;1;42m --- Finishing with code $1. \033[0m"
    echo -e "\033[37;1;42m --- Bye. \033[0m"
    echo
    exit $1
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
prepare_minikube || error 
start_minikube || error
prepare_env || error
minikube_create_namespace dev || error
minikube_create_namespace prod || error
prepare_app || error

# Build dev
minikube_set_context dev || error
minikube_build nginx dev || error
minikube_build php dev || error
minikube_build test dev || error

# Autotest
docker-compose -f cdnnow-autotest-dev.yaml up --abort-on-container-exit --exit-code-from test || error

# Deploy to dev
minikube_deploy dev || error

# Build prod
minikube_set_context prod || error
minikube_build nginx prod || error
minikube_build php prod || error

# Deploy to prod
minikube_deploy prod || error

# Start application here
minicube_start_console prod
pause

# Cleanup stage
minikube_cleanup dev
minikube_cleanup prod
files_cleanup

# Finishin
finish 0
