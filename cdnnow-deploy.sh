#!/bin/bash

echo on

#Variables
PROJECT_NAME="cdnnow"
#PROJECT_ROOT="/home/`whoami`/Projects/$PROJECT_NAME"
PROJECT_ROOT="./"
PROJECT_APP1="nginx"
PROJECT_APP2="php"
PROJECT_CODE="app"
PROJECT_TEMPLATES="templates"
PROJECT_AUTOTEST="test"
BULD_TAG=""
BUILD_YAML="cdnnow-build.yaml"
AUTOTEST_YAML="cdnnow-autotest.yaml"
DEPLOY_TEST_YAML="cdnnow-start.stage.yaml"
DEPLOY_PROD_YAML="cdnnow-start.production.yaml"
START_PROD_YAML="cdnnow-start.production.yaml"
IMAGES_REPO=""
STAGE_ENTRY=""
PROD_ENTRY=""
NOW=`date +"%Y-%m-%d_%H-%M-%S_%Z"`

#Functions
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
    docker rm $(docker ps -a -q --filter="name=$PROJECT_NAME*")
    echo
    echo " --- Removing images"
    docker rmi $(docker images "$PROJECT_NAME*" -a -q) --force
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
echo "Now is $NOW"
echo "Project name is $PROJECT_NAME"
echo "Project root is $PROJECT_ROOT"
echo "Project app1 here $PROJECT_ROOT/$PROJECT_APP1"
echo "Project app2 here $PROJECT_ROOT/$PROJECT_APP2"
echo "Project code here $PROJECT_ROOT/$PROJECT_CODE"
echo "Project autotest here $PROJECT_ROOT/$PROJECT_AUTOTEST"

# Preare

prepare_app || error

# Build stage
build $BUILD_YAML || error

# Autotest stage
autotest $BUILD_YAML $AUTOTEST_YAML $PROJECT_AUTOTEST || error

# Saving images to repository
saveimage

# Deploy to stage

# Deploy to prod

# Start application here

start_console $START_PROD_YAML

# Cleanup stage
cleanup

# Finishin
finish 0
