ARG base_image="nvidia/opengl"
ARG base_tag="base-ubuntu22.04"
ARG branch="development"
ARG robocomp_version="ros"
ARG ros_version="humble-ros-core-jammy"

FROM ${base_image}:${base_tag} AS dependencies-version
ARG USERNAME=demo
ARG USER_UID=1000
ARG USER_GID=$USER_UID
# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG branch
# DEFAULT LD_LIBRARY_PATH variables from the nvidia/opengl image confuses pyside2 about the qt5 Library paths
ENV LD_LIBRARY_PATH="/lib:/usr/lib"
RUN export LD_LIBRARY_PATH="/lib:/usr/lib"
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME --create-home \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
# Install main dependencies
RUN apt-get update && apt-get install -y --no-install-recommends  \
      ca-certificates \
      curl \
    && rm -rf /var/lib/apt/lists/*
RUN cd ~ && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/resources/robocomp_prerequisites_install.sh | bash -s $branch
USER $USERNAME
WORKDIR /home/$USERNAME/


FROM dependencies-version AS base-version
ARG branch
ARG USERNAME=demo
# Using robocomp installation script
RUN cd $HOME && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/robocomp_install.sh | bash -s $branch
RUN export ROBOCOMP=/home/$USERNAME/robocomp
USER $USERNAME
WORKDIR /home/$USERNAME/robocomp
RUN mkdir -p build && cd build && cmake .. && make -j$(nproc)
USER root
RUN cd build && make install
USER $USERNAME
WORKDIR /home/$USERNAME/robocomp
RUN git annex get \
  files/innermodel/simpleworld.xml \
  files/osgModels/textures/wood.jpg \
  files/innermodel/tar36h11-*.png \
  files/osgModels/textures/Metal.jpg \
  files/osgModels/robex/robex.ive
RUN cp -r -L files /home/$USERNAME/files 2>/dev/null || :

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

# Third party dependencies
RUN curl -S https://raw.githubusercontent.com/grupo-avispa/cortex/development/installation.sh | bash -x
USER $USERNAME

FROM ros:${ros_version} AS ros-version
ARG USERNAME=demo
ARG USER_UID=1000
ARG USER_GID=$USER_UID
# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ARG branch
# DEFAULT LD_LIBRARY_PATH variables from the nvidia/opengl image confuses pyside2 about the qt5 Library paths
ENV LD_LIBRARY_PATH="/lib:/usr/lib"
RUN export LD_LIBRARY_PATH="/lib:/usr/lib"
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME --create-home \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
# Install main dependencies
RUN apt-get update && apt-get install -y --no-install-recommends  \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*
RUN cd ~ && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/resources/robocomp_prerequisites_install.sh | bash -s $branch
USER $USERNAME
WORKDIR /home/$USERNAME/
# Using robocomp installation script
RUN cd $HOME && export branch=$branch \
    && curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/robocomp_install.sh | bash -s $branch
RUN export ROBOCOMP=/home/$USERNAME/robocomp
USER $USERNAME
WORKDIR /home/$USERNAME/robocomp
RUN mkdir -p build && cd build && cmake .. && make -j$(nproc)
USER root
RUN cd build && make install
USER $USERNAME
WORKDIR /home/$USERNAME/robocomp
RUN git annex get \
    files/innermodel/simpleworld.xml \
    files/osgModels/textures/wood.jpg \
    files/innermodel/tar36h11-*.png \
    files/osgModels/textures/Metal.jpg \
    files/osgModels/robex/robex.ive
RUN cp -r -L files /home/$USERNAME/files 2>/dev/null || :
# Install DSR
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

# Third party dependencies
RUN curl -S https://raw.githubusercontent.com/grupo-avispa/cortex/development/installation.sh | bash -x
USER $USERNAME

FROM ${robocomp_version}-version AS final
ARG robocomp_version
RUN echo "Built ${robocomp_version}"
CMD ["/bin/bash"]
