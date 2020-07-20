FROM gds_py:latest
#FROM darribas/gds_py:4.1

MAINTAINER Dani Arribas-Bel <D.Arribas-Bel@liverpool.ac.uk>

# https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/Dockerfile
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

USER root

# Remove Conda from path to not interfere with R install
RUN echo ${PATH}
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
RUN echo ${PATH}

#----------------------------------------------------------------------------
#- Rocker setup -------------------------------------------------------------
# https://github.com/rocker-org/rocker-versioned2#version-stable-rocker-images-for-r--400
#----------------------------------------------------------------------------
#-   R   --------------------------------------------------------------------

WORKDIR /
ENV R_VERSION=4.0.2
ENV TERM=xterm
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV R_HOME=/usr/local/lib/R
ENV CRAN=https://packagemanager.rstudio.com/all/__linux__/focal/latest
ENV TZ=UTC
RUN mkdir /rocker_scripts \
 && wget -O /rocker_scripts/install_R.sh \
    https://github.com/rocker-org/rocker-versioned2/raw/538743fcf4940b03d22e1625c7024b3304244ca2/scripts/install_R.sh \
 && chmod 770 /rocker_scripts/install_R.sh \
 && /rocker_scripts/install_R.sh \
 && chown root:users ${R_HOME}/site-library \
 && chmod g+ws ${R_HOME}/site-library \
 && echo "%%%R install: install_R executed%%%" \
 && install2.r --error --skipinstalled remotes \
 && echo "%%%R install: remotes installed%%%" \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends \
     wget \
     texlive-xetex \
     texlive-fonts-recommended \
     texlive-plain-generic \
     texlive-fonts-extra \
 && echo "%%%R install: TexLive reinstalled%%%"

#----------------------------------------------------------------------------
#-   tidyverse   ------------------------------------------------------------

RUN wget -O /rocker_scripts/install_tidyverse.sh \
    https://github.com/rocker-org/rocker-versioned2/raw/65309d4d9dac11d3a78dd26ee4bf7b715436db31/scripts/install_tidyverse.sh \
 && chmod 770 /rocker_scripts/install_tidyverse.sh \
 && /rocker_scripts/install_tidyverse.sh

#----------------------------------------------------------------------------
#-   Geospatial   -----------------------------------------------------------

RUN wget -O /rocker_scripts/install_geospatial.sh \
    https://github.com/rocker-org/rocker-versioned2/raw/master/scripts/install_geospatial.sh \
 && chmod 770 /rocker_scripts/install_geospatial.sh \
 && /rocker_scripts/install_geospatial.sh

#----------------------------------------------------------------------------
#-   GDS Extra   ------------------------------------------------------------

RUN add-apt-repository -y ppa:ubuntugis/ubuntugis-experimental \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    dirmngr \
    gpg-agent \
    jq \
    libjq-dev \
    lbzip2 \
    libatk1.0-0 \
    libcairo2-dev \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    liblwgeom-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libssl1.0.0 \
    libssl-dev \
    libudunits2-dev \
    libv8-3.14-dev \
    libx11-6 \
    libxtst6 \
    netcdf-bin \
    protobuf-compiler \
    tk-dev \
    unixodbc-dev \
    wget \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN install2.r --error --skipinstalled \
        arm \
        BiocManager \
        deldir \
        devtools \
        feather \
        geojsonio \
        ggmap \
        GISTools \
        hexbin \
        igraph \
        kableExtra \
        knitr \
        lme4 \
        nlme \
        randomForest \
        RCurl \
        rmarkdown \
        rpostgis \
        RPostgres \
        RSQLite \
        shiny \
        splancs \
        TraMineR \
        tufte

#----------------------------------------------------------------------------

# Re-attach conda to path
ENV PATH="/opt/conda/bin:${PATH}"

#--- R/Python ---#

USER root

RUN ln -s /opt/conda/bin/jupyter /usr/local/bin
RUN R -e "install.packages('IRkernel'); \
          library(IRkernel); \
          IRkernel::installspec(prefix='/opt/conda/');"
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib/:${LD_LIBRARY_PATH}
RUN fix-permissions $HOME \
  && fix-permissions $CONDA_DIR \
  && fix-permissions ${R_HOME}

RUN pip install -U --no-deps rpy2 \
 && rm -rf /home/$NB_USER/.cache/pip \
 && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID
