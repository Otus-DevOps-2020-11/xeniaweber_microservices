#!/bin/bash

EXT_IP=$(yc compute instance get --name docker-host | sed -n '24p' | awk '{print $2}')
green=$(tput setaf 2)
cyan=$(tput setaf 6)
yellow=$(tput setaf 3)
reset=$(tput sgr0)

echo "Run mongo:latets"

docker run -d --network=reddit \
 --network-alias=post0_db \
 --network-alias=comment0_db \
mongo:latest

echo "Run post:1.0"

docker run -d --network=reddit \
 --network-alias=post0 \
 -e POST_DATABASE_HOST=post0_db \
xweber/post:1.0

echo "Run comment:1.0"

docker run -d --network=reddit \
 --network-alias=comment0 \
 -e COMMENT_DATABASE_HOST=comment0_db \
xweber/comment:1.0

echo "Run ui:1.0"

docker run -d --network=reddit \
 -p 9292:9292 \
 -e POST_SERVICE_HOST=post0 \
 -e COMMENT_SERVICE_HOST=comment0 \
xweber/ui:1.0

echo "${green}Containers are runned!${reset}"
echo "${yellow}Check app -${reset} ${cyan}http://$EXT_IP:9292${reset}"
echo "${yellow}You also can create new post -${reset} ${cyan}http://$EXT_IP:9292/new${reset}"
