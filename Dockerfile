FROM ubuntu:16.04
MAINTAINER "Kentaro Kuwata" <kuwata@geo-quantz.com>
ENV container docker
ENV PYTHONUNBUFFERED 1

# Install basic package
RUN apt-get update -y && apt-get -y install binutils libproj-dev libgeos-dev swig zip cmake libavcodec-extra \
    libpq-dev git make libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev curl wget  binutils libstdc++6 libstdc++6-4.7-dev libproj-dev gdal-bin libgeoip-dev libpng-dev \
    libfreetype6-dev libopenmpi-dev openmpi-bin python python-dev gdal-bin python-gdal \
    build-essential \
    checkinstall \
    python \
    python-dev \
    gdal-bin \
    git \
    g++ \
    wget \
    libxml2 libxml2-dev \
    gfortran bison byacc flex csh make cmake wget p7zip-full \
    nano subversion git curl bison flex libjpeg-dev p7zip-full jbigkit-bin libjbig-dev \
    libsm6 python-qt4

RUN apt-get install -y software-properties-common && add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable && \
    apt -y update && apt -y upgrade

RUN apt-get install -y --reinstall libpq5

RUN mkdir -p /src
ENV APP /src
WORKDIR $APP

# Zlib
RUN curl http://zlib.net/zlib-1.2.11.tar.gz -O -L && \
    tar xvfz zlib-1.2.11.tar.gz  && cd zlib-1.2.11 && \
    ./configure --prefix=/usr/local && \
    make -j2 && make install && ldconfig

# Proj4
RUN git clone https://github.com/OSGeo/proj.4.git && \
    cd proj.4/ && mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make && make install && ldconfig

# Lib tiff
RUN curl ftp://download.osgeo.org/libtiff/tiff-4.0.7.tar.gz -O -L && \
    tar xvfz tiff-4.0.7.tar.gz && cd tiff-4.0.7 && \
    ./configure --enable-cxx \
    --with-zlib-include-dir=/usr/local/include --with-zlib-lib-dir=/usr/local/lib \
    --with-jpeg-include-dir=/usr/include --with-jpeg-lib-dir=/usr/lib \
    --without-x --disable-static --prefix=/usr/local && \
    make -j2 && make install && ldconfig

# Lib geotiff
RUN curl http://download.osgeo.org/geotiff/libgeotiff/libgeotiff-1.4.2.tar.gz -O -L && \
    tar xvfz libgeotiff-1.4.2.tar.gz && cd libgeotiff-1.4.2 && \
    ./configure --with-proj=/usr/local --with-zlib --with-jpeg=/usr/local \
    --with-libtiff=/usr/ --prefix=/usr/local/ && \
    make -j3 && make install && ldconfig

# Install pyenv & Anaconda
RUN git clone https://github.com/yyuu/pyenv.git $APP/.pyenv
RUN git clone https://github.com/yyuu/pyenv-virtualenv.git $APP/.pyenv/plugins/pyenv-virtualenv

ENV PYENV_ROOT $APP/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc

ENV anaconda anaconda3-2.5.0

RUN pyenv install $anaconda
RUN pyenv rehash
RUN pyenv global $anaconda
RUN conda update -y conda
ENV PYTHONPATH $APP/.pyenv/versions/$anaconda/lib/python2.7/site-packages
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN source $APP/.pyenv/versions/$anaconda/bin/activate


RUN cd $APP && curl https://github.com/uclouvain/openjpeg/releases/download/v2.1.2/openjpeg-v2.1.2-linux-x86_64.tar.gz -O -L && \
    tar xvfz openjpeg-v2.1.2-linux-x86_64.tar.gz

RUN cd $APP && wget http://download.osgeo.org/gdal/2.1.2/gdal-2.1.2.tar.gz && \
    tar zxvf gdal-2.1.2.tar.gz && \
    cd gdal-2.1.2 && ./configure --with-python --with-openjpeg=$APP/openjpeg-v2.1.2-linux-x86_64 && \
    #--with-ssl=/usr/local/ssl && \
    make -j3 && make install && ldconfig

RUN mkdir /app
WORKDIR /app
ADD . /app

RUN pip install -r /app/requirements.txt

RUN pip install gdal==2.1.0

RUN conda install -y libgcc
RUN conda install -y libgdal==2.1.0