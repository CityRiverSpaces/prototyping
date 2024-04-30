# CRiSp Prototyping

This repository contains initial prototyping material, such as initial input datasets, scripts, and notebooks. 


## Installation

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

## Adding dependencies

Add R dependencies to the `DESCRIPTION` file, then update the `renv.lock` file using:

```
Rscript -e "renv::snapshot(type='explicit')"
```
