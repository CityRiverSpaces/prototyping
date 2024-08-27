# CRiSp Prototyping

This repository contains initial prototyping material, such as initial input datasets, scripts, and notebooks.


## Installation

### R

R (version 4.4) should be installed (see e.g. instructions on [CRAN](https://cran.r-project.org)).
Setup the R environment using `renv` from the lock file:

```shell
Rscript -e "install.packages('renv')"
Rscript -e "renv::restore()"
```

or "from scratch" using the dependencies in the `DESCRIPTION` file (note that the `renv.lock` file needs to be removed):

```
Rscript -e "renv::init(bare=TRUE)"
Rscript -e "renv::install()"
```

**Note for Linux users:** By default, R will install packages from the CRAN repository, which, unfortunately, does not maintain Linux binaries. The commands above will thus build packages from source, taking a very long time to complete (and potentially raising issues with missing system libraries). Instead, one can instruct R to install packages from the RStudio package manager (Posit), which includes binaries for Linux distributions. On [this web page](https://packagemanager.posit.co/client/#/repos/cran/setup?r_environment=other) select the Linux distribution, then copy the following lines  to the `.Rprofile` file, replacing the URL below with the one formatted under "Repository URL":

```R
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/XXXXXXX/latest"))
```

Place the `.Rprofile` file in the project root folder (or in your home directory to add the option for all user projects).  

### Python

Setup the Python environment using `venv`:

```shell
python -m venv venv
source venv/bin/activate
python -m pip install -r requirements.txt
```

### Alternative installation using Conda

An environment with both the R and Python dependencies can be created from the provided `environment.yml` file using Conda (or its faster implementation Mamba). Conda can be installed using the Miniforge scripts provided [here](https://conda-forge.org/miniforge/) (download one of the Mambaforge scripts in order to install Mamba as well), then run:

```
# replace `conda` with `mamba` if using Mambaforge
conda env create -f environment.yml
conda activate crisp
```

## Adding dependencies

Add R dependencies to the `DESCRIPTION` file, then update the `renv.lock` file using:

```
Rscript -e "renv::snapshot(type='explicit')"
```

Add Python dependencies to the `requirements.txt` file.

Both R and Python dependencies should also be added to the conda `environment.yml` file.
