#!/bin/bash

timestamp=$(date +"%F"_"%T")

echo "Set runner token"
read run_token

echo "Add Runner"
docker run -d --name gitlab-runner \
    --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sockgitlab/gitlab-runner:latest

echo "Register runner"
docker exec -it gitlab-runner gitlab-runner register \
    --url http://<your-ip>/ \
    --non-interactive \
    --locked=false \
    --name DockerRunner_$timestamp \
    --executor docker \
    --docker-image alpine:latest \
    --registration-token $run_token \
    --tag-list "linux,xenial,ubuntu,docker" \
    --run-untagged
