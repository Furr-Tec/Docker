FROM jetbrains/teamcity-agent:latest

USER root

# Install required build tools and newer CMake 4.0.3
RUN apt-get update && \
    apt-get install -y build-essential clang ninja-build curl && \
    curl -LO https://github.com/Kitware/CMake/releases/download/v4.0.3/cmake-4.0.3-linux-x86_64.sh && \
    chmod +x cmake-4.0.3-linux-x86_64.sh && \
    ./cmake-4.0.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.0.3-linux-x86_64.sh && \
    apt-get clean

USER buildagent