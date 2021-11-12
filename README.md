# Reproducible R code for the manuscript entitled "Forest loss and fire in the Dominican Republic during the 21st Century"

## How to reproduce

If you want to check the results of the reproducible code, check the PDF version of the `.Rmd` notebooks.

If you want to reproduce the code, follow these instructions:

1. Clone this repo to your computer.

2. Visit ZENODO, download `forest-loss-fire-reproducible-data-repo.zip` (preserve its name, otherwise, the reproducible script may not be able to unzip it automatically) and place the ZIP file in this repo (e.g. in the same directory containing this document).

3. Run the code chunks in each `.Rmd` notebooks, or alternately knit the notebooks.

    - `data-download-preparation.Rmd`.
    
    - `modelling.Rmd`

Note: You will need a working installation of R Programming Language (version 3.3 or greater) to reproduce the code. Check the [Methods for reproducing the code](#methods-for-reproducing-the-code) section for more information.

## Disclaimer

These reproducible scripts are provided "as is", without warranty of any kind.

## Methods for reproducing the code

All the methods presented in this section were developed and tested on a PC running under Linux operating system.

### Using your current installation of R

If the packages listed in the `R/load-packages.R` script (and their dependencies) are already installed in your PC, you can move forward and run the code-chunks following the sequence mentioned in the previous section. Otherwise, all the packages should be installed by hand. This is not the easiest way, but if you are familiar with R packages installation, then I recommend it.

### Using `jmartinez19/rstudio` Docker container

This is the easiest way, because both RStudio IDE and dependencies would be installed in a Docker image. However, keep in mind that you would need at least 5 GB of free disk space.

1. Run the `jmartinez19/rstudio` Docker image. This may take a while the first time you run it.

```
docker run --rm \
  -p 127.0.0.1:8787:8787 \
  -e DISABLE_AUTH=true \
  -v $(pwd):/home/rstudio/forest-loss-fire-reproducible \
  jmartinez19/rstudio
```

2. Open a browser and type "localhost:8787". You should be redirected to RStudio IDE.

3. In the `Files` tab (down-right pane), click on the `forest-loss-fire-reproducible` directory, and then click on the `forest-loss-fire-reproducible.Rproj` file. When asked `Do you want to open the project ~/forest-loss-fire-reproducible?`, click `Yes`.

4. Run the code chunks in the reproducible scripts, or alternately knit the notebooks. Keep in mind that if you knit from RStudio, a message will ask you to allow popup windows, which can be done in the address bar of the browser.

### Using R from a Docker

This method uses 2 GB disk space, which is less than space than previous method, but requires you to run the scripts, since no IDE would be available.

1. Build the docker image. This may take a while the first time you run it.

`docker build -t ff-dr .`

2. Make sure you're on a system running X.

3. Disable access control to X, so clients can connect from any host

`xhost + &`

4. Run a container from the `ff-dr` image in interactive mode

```
docker run -it --rm \
  -v $(pwd):/home/docker \
  --user $(id -u):$(id -g) \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=unix$DISPLAY \
  ff-dr
```

5. IMPORTANT: Reenable X access control:

`xhost -`

6. Run the code chunks in the reproducible scripts, or alternately knit the notebooks.

## Appendix

### How I built the `jmartinez19/rstudio` Docker image:

1. First, I created the `rstudio` container based `rocker/rstudio`, and setting `rstudio` user as sudoer.

```
docker run --rm \
  -p 8787:8787 \
  -e ROOT=TRUE \
  -e PASSWORD=apassword \
  rocker/rstudio
```

2. Then I accesed the RStudio Server via the browser (localhost:8787) as `rstudio` user with the provided password.

3. Installed required packages at the system level using the terminal tab.

```
sudo su
apt update
apt install software-properties-common
apt install libcurl4-openssl-dev libssl-dev unixodbc-dev libpq-dev libxml2-dev
apt install libudunits2-dev libgdal-dev libgeos-dev libproj-dev 
apt install libavfilter-dev libglpk-dev
```

4. In the R console, I installed the required packages by running the contents of the `R/load-packages.R` script (copied from source, pasted in the R console and ran it).

5. From the R console, I installed latex packages:

```
library(tinytex)
install_tinytex()
latex_pkgs <- c('abstract', 'colortbl', 'environ', 'fpl',
                'makecell', 'mathpazo', 'multirow', 'palatino',
                'pdflscape', 'setspace', 'tabu', 'threeparttable',
                'threeparttablex', 'titlesec', 'trimspaces',
                'ulem', 'varwidth', 'wrapfig')
tlmgr_install(latex_pkgs)
```

6. Committed to a new image

```
docker ps # To check the container ID, in this case
docker commit -m "Add dependencies" c77b73f86dbd jmartinez19/rstudio
```

7. Created remote repo jmartinez19/rstudio in the Docker Hub: https://hub.docker.com

8. Finally, I pushed to the remote repo

```
docker login #Credentials already available in my local machine
docker push jmartinez19/rstudio
```
