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
