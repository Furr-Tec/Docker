FROM jetbrains/teamcity-agent:latest

USER root

RUN apt-get update && \
    apt-get install -y cmake build-essential clang ninja-build && \
    apt-get clean

USER buildagent