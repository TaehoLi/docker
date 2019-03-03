ARG VERSION_ID
FROM ubuntu:${VERSION_ID}

# packaging dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        dh-make \
        fakeroot \
        build-essential \
        devscripts \
        lsb-release && \
    rm -rf /var/lib/apt/lists/*

# packaging
ARG PKG_VERS
ARG PKG_REV
ARG RUNTIME_VERSION
ARG DOCKER_VERSION

ENV DEBFULLNAME "NVIDIA CORPORATION"
ENV DEBEMAIL "cudatools@nvidia.com"
ENV REVISION "$PKG_VERS-$PKG_REV"
ENV RUNTIME_VERSION $RUNTIME_VERSION
ENV DOCKER_VERSION $DOCKER_VERSION
ENV SECTION ""

# output directory
ENV DIST_DIR=/tmp/nvidia-docker2-$PKG_VERS
RUN mkdir -p $DIST_DIR /dist

# nvidia-docker 2.0
COPY nvidia-docker $DIST_DIR/nvidia-docker
COPY daemon.json $DIST_DIR/daemon.json

WORKDIR $DIST_DIR
COPY debian ./debian


RUN sed -i "s;@VERSION@;${REVISION#*+};" debian/changelog && \
    if [ "$REVISION" != "$(dpkg-parsechangelog --show-field=Version)" ]; then exit 1; fi

CMD export DISTRIB="$(lsb_release -cs)" && \
    debuild --preserve-env --dpkg-buildpackage-hook='sh debian/prepare' -i -us -uc -b && \
    mv /tmp/*.deb /dist
    
    
    
    
    
FROM debian:latest

#  $ docker build . -t continuumio/anaconda3:latest -t continuumio/anaconda3:5.3.0
#  $ docker run --rm -it continuumio/anaconda3:latest /bin/bash
#  $ docker push continuumio/anaconda3:latest
#  $ docker push continuumio/anaconda3:5.3.0

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
