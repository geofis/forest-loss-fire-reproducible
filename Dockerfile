# Base + R + tidyverse original image: https://hub.docker.com/u/oliverstatworx/
FROM jmartinez19/base-r-tidyverse-sf:latest

# Working directory
WORKDIR /home/docker

# Entrypoint
ENTRYPOINT ["R"]
