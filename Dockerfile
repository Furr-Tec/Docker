FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl \
    unzip \
    openjdk-17-jre-headless \
    build-essential \
    cmake \
    ninja-build \
    git \
    wget \
    ca-certificates \
    && apt clean

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN useradd -m teamcity && mkdir -p /opt/teamcity-agent
WORKDIR /opt/teamcity-agent

RUN curl -O http://<YOUR_TEAMCITY_SERVER>:8111/update/buildAgent.zip && \
    unzip buildAgent.zip && rm buildAgent.zip

CMD ["./bin/agent.sh", "run"]