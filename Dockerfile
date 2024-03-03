FROM ubuntu:22.04

RUN apt update
RUN apt install -y gcc-multilib g++-multilib
RUN apt install -y make
