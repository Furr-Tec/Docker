FROM jetbrains/teamcity-agent:latest

USER root

# Set frontend to noninteractive to avoid prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Update package lists and install PPA management tools.
# --no-install-recommends keeps the image smaller.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        gnupg2

# Step 2: Add the GCC toolchain PPA and update package lists again
# to fetch the contents of the new repository.
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update

# Step 3: Install the newer compilers and other build tools.
# This command should now find gcc-14 and g++-14 from the PPA.
RUN apt-get install -y --no-install-recommends \
    build-essential \
    gcc-14 \
    g++-14 \
    clang \
    ninja-build \
    curl

# Step 4: Configure update-alternatives to make GCC/G++ 14 the default.
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# Step 5: Install the corrected CMake version.
RUN curl -fLO https://github.com/Kitware/CMake/releases/download/v3.29.3/cmake-3.29.3-linux-x86_64.sh && \
    chmod +x cmake-3.29.3-linux-x86_64.sh && \
    ./cmake-3.29.3-linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm cmake-3.29.3-linux-x86_64.sh

# Step 6: Clean up to reduce final image size.
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Switch back to the non-root user
USER buildagent