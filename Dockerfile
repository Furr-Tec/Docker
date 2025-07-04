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
        software-properties-common \
        wget

# Step 2: Add the ubuntu-toolchain-r PPA using add-apt-repository (more reliable)
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test

# Step 3: Update package lists to load the new package information
RUN apt-get update

# Step 4: Install the compilers and build tools with GCC-15 for full C++26 support
RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-15 \
    g++-15 \
    clang \
    ninja-build \
    mingw-w64 \
    gcc-mingw-w64 \
    g++-mingw-w64 || \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc-14 \
    g++-14 \
    clang \
    ninja-build \
    mingw-w64 \
    gcc-mingw-w64 \
    g++-mingw-w64

# Step 5: Configure update-alternatives to make the installed GCC/G++ the default (Linux target)
RUN if [ -f /usr/bin/gcc-15 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100; \
    elif [ -f /usr/bin/gcc-14 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100; \
    fi

# Step 5b: Set up MinGW cross-compiler alternatives (Windows target)
RUN update-alternatives --install /usr/bin/x86_64-w64-mingw32-gcc x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix 100 && \
    update-alternatives --install /usr/bin/x86_64-w64-mingw32-g++ x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix 100 && \
    update-alternatives --install /usr/bin/i686-w64-mingw32-gcc i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix 100 && \
    update-alternatives --install /usr/bin/i686-w64-mingw32-g++ i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix 100

# Step 6: Install Java 21 for TeamCity compatibility
RUN wget -O- https://apt.corretto.aws/corretto.key | apt-key add - && \
    add-apt-repository 'deb https://apt.corretto.aws stable main' && \
    apt-get update && \
    apt-get install -y --no-install-recommends java-21-amazon-corretto-jdk

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto

# Step 7: Install the latest CMake RC version (4.0.3)
RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v4.0.3/cmake-4.0.3-linux-x86_64.sh && \
    chmod +x cmake-4.0.3-linux-x86_64.sh && \
    ./cmake-4.0.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-4.0.3-linux-x86_64.sh

# Step 8: Clean up to reduce final image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER buildagent