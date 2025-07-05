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

# Step 4: Install the compilers and build tools with latest available GCC
RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-14 \
    g++-14 \
    clang \
    ninja-build \
    mingw-w64 \
    gcc-mingw-w64-x86-64 \
    gcc-mingw-w64-i686 \
    g++-mingw-w64-x86-64 \
    g++-mingw-w64-i686 || \
    apt-get install -y --no-install-recommends \
    build-essential \
    gcc-13 \
    g++-13 \
    clang \
    ninja-build \
    mingw-w64 \
    gcc-mingw-w64-x86-64 \
    gcc-mingw-w64-i686 \
    g++-mingw-w64-x86-64 \
    g++-mingw-w64-i686

# Step 4b: Install MinGW-w64 GCC 15 from furr-tec.ch server (reliable)
RUN echo "Installing MinGW-w64 GCC 15 from furr-tec.ch..." && \
    cd /tmp && \
    # Download from reliable furr-tec.ch server
    echo "Downloading MinGW-w64 GCC 15..." && \
    wget --progress=bar:force --timeout=30 --tries=3 \
         "https://furr-tec.ch/mingw-w64_gcc-15-win64.tar.bz2" \
         -O mingw-gcc15.tar.bz2 && \
    echo "Download successful, extracting..." && \
    tar -xf mingw-gcc15.tar.bz2 -C /opt/ && \
    # Debug: show what was actually extracted
    echo "Contents of /opt after extraction:" && \
    ls -la /opt/ && \
    # The archive extracts the cross directory directly into /opt/
    # Rename it to mingw-gcc15 for consistency
    if [ -d "/opt/cross" ]; then \
        mv "/opt/cross" /opt/mingw-gcc15; \
        echo "Renamed /opt/cross to /opt/mingw-gcc15"; \
    fi && \
    echo "Final MinGW directory structure:" && \
    ls -la /opt/mingw-gcc15/ && \
    echo "Looking for binaries in bin/:" && \
    ls -la "/opt/mingw-gcc15/bin/" | head -5 && \
    # Create direct symlinks to avoid circular references
    if [ -f "/opt/mingw-gcc15/bin/x86_64-w64-mingw32-gcc" ]; then \
        # Remove any existing symlinks first
        rm -f /usr/local/bin/x86_64-w64-mingw32-gcc-15 /usr/local/bin/x86_64-w64-mingw32-g++-15 /usr/local/bin/x86_64-w64-mingw32-windres-15 && \
        # Create fresh symlinks to bin directory (cross was renamed to mingw-gcc15)
        ln -s "/opt/mingw-gcc15/bin/x86_64-w64-mingw32-gcc" /usr/local/bin/x86_64-w64-mingw32-gcc-15 && \
        ln -s "/opt/mingw-gcc15/bin/x86_64-w64-mingw32-g++" /usr/local/bin/x86_64-w64-mingw32-g++-15 && \
        ln -s "/opt/mingw-gcc15/bin/x86_64-w64-mingw32-windres" /usr/local/bin/x86_64-w64-mingw32-windres-15 && \
        echo "MinGW cross-compiler installed successfully" && \
        /usr/local/bin/x86_64-w64-mingw32-gcc-15 --version && \
        # Test C++ support (try C++26, fall back to C++20)
        echo 'int main() { return 0; }' > /tmp/test.cpp && \
        (echo "Testing C++26 support..." && \
         /usr/local/bin/x86_64-w64-mingw32-g++-15 -std=c++26 /tmp/test.cpp -o /tmp/test.exe 2>/dev/null && \
         echo "C++26 support confirmed" && rm /tmp/test.exe) || \
        (echo "C++26 not supported, testing C++20..." && \
         /usr/local/bin/x86_64-w64-mingw32-g++-15 -std=c++20 /tmp/test.cpp -o /tmp/test.exe 2>/dev/null && \
         echo "C++20 support confirmed" && rm /tmp/test.exe) || \
        (echo "C++20 not supported, testing C++2a..." && \
         /usr/local/bin/x86_64-w64-mingw32-g++-15 -std=c++2a /tmp/test.cpp -o /tmp/test.exe && \
         echo "C++2a (experimental C++20) support confirmed" && rm /tmp/test.exe) && \
        rm /tmp/test.cpp; \
    else \
        echo "ERROR: MinGW binaries not found in /opt/mingw-gcc15/bin/"; \
        echo "Directory structure:" && \
        ls -la "/opt/mingw-gcc15/" || true; \
        if [ -d "/opt/mingw-gcc15/bin" ]; then \
            echo "Bin directory contents:" && \
            ls -la "/opt/mingw-gcc15/bin/" || true; \
        fi; \
        exit 1; \
    fi && \
    rm /tmp/mingw-gcc15.tar.bz2

# Step 5: Configure update-alternatives to make the installed GCC/G++ the default (Linux target)
RUN if [ -f /usr/bin/gcc-14 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100; \
    elif [ -f /usr/bin/gcc-13 ]; then \
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 && \
        update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100; \
    fi

# Step 5b: Set up MinGW cross-compiler (skip alternatives to avoid symlink issues)
RUN echo "Setting up system MinGW alternatives..." && \
    update-alternatives --install /usr/bin/x86_64-w64-mingw32-gcc x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix 100 && \
    update-alternatives --install /usr/bin/x86_64-w64-mingw32-g++ x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix 100 && \
    update-alternatives --install /usr/bin/i686-w64-mingw32-gcc i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix 100 && \
    update-alternatives --install /usr/bin/i686-w64-mingw32-g++ i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix 100 && \
    # Show what we got
    echo "System MinGW GCC version:" && x86_64-w64-mingw32-gcc --version && \
    # Show custom MinGW if available (without using alternatives)
    if [ -L /usr/local/bin/x86_64-w64-mingw32-gcc-15 ]; then \
        echo "Custom MinGW also available at:" && \
        /usr/local/bin/x86_64-w64-mingw32-gcc-15 --version || echo "Custom MinGW has symlink issues"; \
    fi

# Step 5c: Install GCC-15.1.0 from source for full C++26 support (this takes time but gives latest features)
RUN apt-get install -y --no-install-recommends \
        libgmp-dev libmpfr-dev libmpc-dev flex bison && \
    cd /tmp && \
    wget https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-15.1.0/gcc-15.1.0.tar.xz && \
    tar -xf gcc-15.1.0.tar.xz && \
    cd gcc-15.1.0 && \
    ./configure --prefix=/usr/local/gcc-15 --enable-languages=c,c++ --disable-multilib --disable-bootstrap && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/gcc-15.1.0* && \
    update-alternatives --install /usr/bin/gcc gcc /usr/local/gcc-15/bin/gcc 200 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/local/gcc-15/bin/g++ 200

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