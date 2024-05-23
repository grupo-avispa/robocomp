ARG base_image="nvidia/opengl"
ARG base_tag="base-ubuntu22.04"
ARG branch="development"
ARG robocomp_version="dsr"

FROM ${base_image}:${base_tag} AS dependencies-version
# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
ARG branch
# DEFAULT LD_LIBRARY_PATH vaiables from the nvidia/opengl image confuses pyside2 about the qt5 Library paths
ENV LD_LIBRARY_PATH="/lib:/usr/lib"
RUN export LD_LIBRARY_PATH="/lib:/usr/lib"
RUN apt-get update && apt-get install -y --no-install-recommends  \
      ca-certificates \
      curl \
      sudo \
    && rm -rf /var/lib/apt/lists/*
RUN cd ~ && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/resources/robocomp_prerequisites_install.sh | bash -s $branch
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/demo && \
    echo "demo:x:${uid}:${gid}:demo,,,:/home/demo:/bin/bash" >> /etc/passwd && \
    echo "demo:x:${uid}:" >> /etc/group && \
    echo "demo:demo"|chpasswd && \
    echo "demo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/demo-user && \
    chown ${uid}:${gid} -R /home/demo
USER demo
WORKDIR /home/demo/


FROM dependencies-version AS base-version
ARG branch
# Using robocomp installation script
RUN cd ~ && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/robocomp_install.sh | bash -s $branch
ENV PATH=$PATH:/opt/robocomp/bin/:'/home/demo/.local/bin'
ENV ROBOCOMP=/home/demo/robocomp
RUN export ROBOCOMP=/home/demo/robocomp
RUN export PATH=$PATH:/opt/robocomp/bin/:'/home/demo/.local/bin'
USER demo
RUN cd /home/demo/robocomp && mkdir -p build && cd build && cmake .. && make -j$(nproc)
USER root
RUN cd /home/demo/robocomp/build && make install
USER demo
WORKDIR robocomp
RUN git annex get \
  files/innermodel/simpleworld.xml \
  files/osgModels/textures/wood.jpg \
  files/innermodel/tar36h11-*.png \
  files/osgModels/textures/Metal.jpg \
  files/osgModels/robex/robex.ive
RUN cp -r -L files /home/demo/files 2>/dev/null || :

FROM base-version AS dsr-version
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
  libasio-dev \
  libtinyxml2-dev \
  libopencv-dev \
  libqglviewer-dev-qt5 \
  libeigen3-dev \
  python3-dev \
  python3-pybind11 \
  && rm -rf /var/lib/apt/lists/*

# ICE fix
COPY Connection.h /usr/include/Ice/Connection.h

### Third party dependencies
RUN curl -S https://raw.githubusercontent.com/grupo-avispa/cortex/development/installation.sh | bash -x
RUN rm -r /usr/local/include/cppitertools
RUN git clone https://github.com/ryanhaining/cppitertools /usr/local/include/cppitertools
USER demo


FROM ${robocomp_version}-version AS final
ARG robocomp_version
RUN echo "Built ${robocomp_version}"
