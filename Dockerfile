ARG UBUNTU_RELEASE=20.04
ARG CUDA_VERSION=11.2.2

FROM nvcr.io/nvidia/cudagl:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_RELEASE}

ARG DISTRO="foxy"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&  apt-get install locales && locale-gen en_US en_US.UTF-8 \
  &&  update-locale LC_ALL=en_US.UTF-8 \
  && LANG=en_US.UTF-8 \
  &&  rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

# Install ros2
RUN  apt-get update \
  && apt-get install curl software-properties-common -y \
  && add-apt-repository --yes universe \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
  && apt-get update \
  && apt-get install -y --no-install-recommends ros-${DISTRO}-desktop \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# install colcon and rosdep
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-colcon-common-extensions \
        python3-rosdep \
        ros-dev-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and assign adequate groups
RUN groupadd -g 1000 user && \
    useradd -ms /bin/bash user -u 1000 -g 1000 && \
    usermod -a -G adm,audio,cdrom,dialout,dip,fax,floppy,lp,plugdev,sudo,tape,tty,video,voice user && \
    echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    chown user:user /home/user

USER user
ENV USER=user
WORKDIR /home/user

# initialize rosdep
RUN sudo rosdep init && \
    rosdep update

RUN echo "source /opt/ros/${DISTRO}/setup.bash" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc
