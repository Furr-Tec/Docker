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
        gnupg

# Step 2: Manually download the PPA's GPG signing key
RUN mkdir -p /etc/apt/keyrings && \
    curl -sS "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x60C317803A41BA51845E371A1E9377A2BA9EF27F" | gpg --dearmor -o /etc/apt/keyrings/ubuntu-toolchain-r-test-keyring.gpg

# Step 3: Manually add the PPA's repository source list
# The 'lsb_release -cs' command automatically gets the Ubuntu version name (e.g., "jammy")
RUN echo "deb [signed-by=/etc/apt/keyrings/ubuntu-toolchain-r-test-keyring.gpg] http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/ubuntu-toolchain-r-test.list

# Step 4: Update package lists to finally load the new package information
RUN apt-get update

# Step 5: Install the compilers and build tools. This should now succeed.
RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-14 \
    g++-14 \
    clang \
    ninja-build

# Step 6: Configure update-alternatives to make GCC/G++ 14 the default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# Step 7: Install the corrected CMake version
RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v3.29.3/cmake-3.29.3-linux-x86_64.sh && \
    chmod +x cmake-3.29.3-linux-x86_64.sh && \
    ./cmake-3.29.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-3.29.3-linux-x86_64.sh

# Step 8: Clean up to reduce final image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER buildagent