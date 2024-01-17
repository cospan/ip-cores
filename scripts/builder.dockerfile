# Dockerfile for Cocotb Build, original taken from: https://github.com/ravi-chandran/dockerize-tutorial/blob/master/swbuilder/install_swbuilder.dockerfile
FROM ubuntu:20.04
LABEL maintainer="Dave McCoy"

SHELL ["/bin/bash", "-c"]


# Create non-root user:group and generate a home directory to support SSH
ARG USERNAME
RUN adduser --disabled-password --gecos '' ${USERNAME} \
    && adduser ${USERNAME} sudo                        \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install SW build system inside docker
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
       apt-get -y --quiet --no-install-recommends install \
       build-essential gtkwave iverilog python3 python3-pip\
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -fr /var/lib/apt/lists/{apt,dpkg,cache,log} /tmp/* /var/tmp/*

RUN pip3 install cocotb cocotb-bus cocotbext-axi pytest find_libpython

# Run container as non-root user from here onwards
# so that build output files have the correct owner
USER ${USERNAME}

# set up volumes
VOLUME /scripts
VOLUME /workdir

# run bash script and process the input command
ENTRYPOINT [ "/bin/bash", "/scripts/run_build.sh"]
#ENTRYPOINT [ "/bin/bash"]
