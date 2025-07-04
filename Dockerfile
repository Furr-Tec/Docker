FROM jetbrains/teamcity-agent:latest

USER root

# 1. Install prerequisites for adding repositories
# 2. Add the PPA for the latest GCC toolchains
# 3. Update package lists to include packages from the new PPA
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update

# 4. Install GCC 14, G++ 14, and other required build tools
RUN apt-get install -y \
    build-essential \
    gcc-14 \
    g++-14 \
    clang \
    ninja-build \
    curl

# 5. Configure update-alternatives to make GCC/G++ 14 the default compiler
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# 6. Install a recent, valid version of CMake (e.g., 3.29.3)
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.29.3/cmake-3.29.3-linux-x86_64.sh && \
    chmod +x cmake-3.29.3-linux-x86_64.sh && \
    ./cmake-3.29.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-3.29.3-linux-x86_64.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to the non-root buildagent user
USER buildagent