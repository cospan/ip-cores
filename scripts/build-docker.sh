#! /bin/bash

time docker image build                 \
    --file install_swbuilder.dockerfile \
    --tag cocotb-builder .

docker image ls
