#!/bin/sh

echo -en "\033[37;1;42m Check start page: \033[0m"

curl -H "Host: cdnnow.tarh.home" --silent --show-error --fail -I http://nginx/index.php
