# Using a specific Ubuntu-based version for stability instead of 'latest'
FROM jetbrains/teamcity-agent:2024.03.2-linux-sudo

USER root

# Set frontend to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Update and install necessary tools for managing GPG keys and sources
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common

# Step 2: Add the ubuntu-toolchain-r PPA using add-apt-repository (more reliable)
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test

# Step 3: Update package lists to load the new package information
RUN apt-get update

# Step 4: Install the compilers and build tools with fallback versions
RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-13 \
    g++-13 \
    clang \
    ninja-build || \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc-12 \
    g++-12 \
    clang \
    ninja-build

# Step 5: Configure update-alternatives to make the installed GCC/G++ the default
RUN if [ -f /usr/bin/gcc-13 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100; \
    elif [ -f /usr/bin/gcc-12 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100; \
    fi

# Step 6: Install the latest CMake RC version (4.0.3)
RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v4.0.3/cmake-4.0.3-linux-x86_64.sh && \
    chmod +x cmake-4.0.3-linux-x86_64.sh && \
    ./cmake-4.0.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.0.3-linux-x86_64.sh

# Step 7: Clean up to reduce final image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER buildagent
