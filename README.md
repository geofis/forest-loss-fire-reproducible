# Reproducible R code for the manuscript entitled "Forest loss and fire in the Dominican Republic during the 21st Century"

José Ramón Martínez Batlle
Universidad Autónoma de Santo Domingo (UASD)
jmartinez19\@uasd.edu.do

[![DOI](https://zenodo.org/badge/421058260.svg)](https://zenodo.org/badge/latestdoi/421058260)

Cite this repo using the following format (BibTeX entry [here](#bibtex-entry-for-this-repo)): "José Ramón Martínez Batlle. (2021). geofis/forest-loss-fire-reproducible: First release (v0.0.0.9000). Zenodo. https://doi.org/10.5281/zenodo.5694017"

If you want to cite the manuscript as well, use the following format: "Martínez Batlle, J. R. (2021). Forest loss and fire in the Dominican Republic during the 21st Century. *bioRxiv*. https://doi.org/10.1101/2021.06.15.448604"

## How to reproduce

If you want to check the results of the reproducible code, check the PDF version of the `.Rmd` notebooks.

If you want to reproduce the code, follow these instructions:

1. Clone this repo to your computer. From a terminal window, this should work: `git clone https://github.com/geofis/forest-loss-fire-reproducible.git`. If you are using RStudio on a desktop version, use the `New Project>Version Control>Git` pipeline.

2. Visit [ZENODO](https://zenodo.org/record/5681481), download the dataset `forest-loss-fire-reproducible-data-repo.zip` (preserve its name, otherwise, the reproducible script may not be able to unzip it automatically) and place the ZIP file in the cloned repo directory (named `forest-loss-fire-reproducible/`).

3. Run the code chunks in the `.Rmd` notebooks, or alternately knit the notebooks. As a suggestion, run the `.Rmd` in the sequence below:

    - `data-download-preparation.Rmd`.
    
    - `modelling.Rmd`

Note: You will need a working installation of R Programming Language (version 3.3 or greater) to reproduce the code. Check the [Methods for reproducing the code](#methods-for-reproducing-the-code) section for more information.

## Disclaimer

These reproducible scripts are provided "as is", without warranty of any kind.

## Methods for reproducing the code

All the methods presented in this section were developed and tested on a Linux PC.

### Using your current installation of R

If the packages listed in the `R/load-packages.R` script (and their dependencies) are already installed in your PC, you can move forward and run the code chunks following the sequence mentioned in the [How to reproduce section](#how-to-reproduce) section. Otherwise, all the packages should be installed by hand. This is not the easiest way, but if you are familiar with R packages installation, then I recommend it.

### Using `jmartinez19/rstudio` Docker container

This is the easiest way, because both RStudio IDE and package dependencies would be pulled from a Docker image. However, keep in mind that you will need at least 5 GB of free disk space.

1. From the cloned repo directory (see ["How to reproduce"](#how-to-reproduce) for instructions on cloning), run the `jmartinez19/rstudio` Docker image. This may take a while the first time you run it.

```
docker run --rm \
  -p 127.0.0.1:8787:8787 \
  -e DISABLE_AUTH=true \
  -v $(pwd):/home/rstudio/forest-loss-fire-reproducible \
  jmartinez19/rstudio
```

2. When Docker finishes pulling the image, open a browser and type [localhost:8787](localhost:8787) in the address bar. You should be redirected to RStudio IDE.

3. In the `Files` tab (down-right pane), click on the `forest-loss-fire-reproducible` directory, and then click on the `forest-loss-fire-reproducible.Rproj` file. When asked `Do you want to open the project ~/forest-loss-fire-reproducible?`, click `Yes`.

4. Download the `forest-loss-fire-reproducible-data-repo.zip` dataset from [ZENODO](https://zenodo.org/record/5681481) if you have not already done so.

5. Run the code chunks in the reproducible scripts, or alternately knit the notebooks. Keep in mind that if you knit from RStudio, a message will ask you to allow popup windows, which can be done in the address bar of the browser.

### Using R from a Docker container

This method uses 2 GB disk space, which is less than space than previous method, but requires you to run the scripts, since no IDE would be available. You can also knit the `.Rmd` notebooks from the R console; [click here](https://bookdown.org/yihui/rmarkdown/compile.html) for instructions.

1. From the cloned repo directory (see ["How to reproduce"](#how-to-reproduce) for instructions on cloning), build the docker image. This may take a while the first time you run it.

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

6. Download the `forest-loss-fire-reproducible-data-repo.zip` dataset from [ZENODO](https://zenodo.org/record/5681481) if you have not already done so.

7. Run the code chunks in the reproducible scripts, or alternately knit the notebooks.

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

### Bibtex entry for this repo

```
@software{jose_ramon_martinez_batlle_2021_5694017,
  author       = {José Ramón Martínez Batlle},
  title        = {{geofis/forest-loss-fire-reproducible: First 
                   release}},
  month        = nov,
  year         = 2021,
  publisher    = {Zenodo},
  version      = {v0.0.0.9000},
  doi          = {10.5281/zenodo.5694017},
  url          = {https://doi.org/10.5281/zenodo.5694017}
}
```
