# CRiSp Prototyping

This repository contains initial prototyping material, such as initial input datasets, scripts, and notebooks. 


## Installation

Install the Python dependencies in a virtual environments, e.g. using `venv`:

```
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Setup the R environment using `renv` from the lock file:

```shell
Rscript -e "install.packages('renv')"
Rscript -e "renv::restore()"
```

or "from scratch" using the dependencies in the `DESCRIPTION` file:

```
Rscript -e "renv::init(bare=TRUE)"
Rscript -e "renv::install()"
```

Setup the R kernel for Jupyter using:

```
Rscript -e "IRkernel::installspec()"
```

## Adding dependencies

For Python dependencies, add the package name to the `requirements.txt` file.
For R dependencies, add the package name to the `DESCRIPTION` file, then update the `renv.lock` file using:

```
Rscript -e "renv::snapshot(type='explicit')"
```
