FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update && apt-get install -y locales && \
  rm -rf /var/lib/apt/lists/* && \
  locale-gen de_DE.UTF-8
ENV LANG de_DE.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL de_DE.UTF-8