FROM openjdk:8-jdk

# set Env
ENV ANDROID_SDK_TOOLS="3859397" \
    ANDROID_BUILD_TOOLS="28.0.3" \
    ANDROID_COMPILE_SDK="28" \
    SDK_ROOT="/sdk" \
    ANDROID_HOME="${SDK_ROOT}" \
    ANDROID_NDK_HOME="${SDK_ROOT}/ndk-bundle/" \
    PATH="$PATH:${SDK_ROOT}/platform-tools/"

RUN apt-get --quiet update --yes && \
    apt-get --quiet install --no-install-recommends  --yes git wget tar unzip lib32stdc++6 lib32z1 && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS}.zip && \
    unzip -qq android-sdk.zip -d ${SDK_ROOT} && \
    mkdir -p /root/.android && \
    touch /root/.android/repositories.cfg && \
    mkdir -p ${SDK_ROOT}/licenses && \
    echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > ${SDK_ROOT}/licenses/android-sdk-license && \
    echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > ${SDK_ROOT}/licenses/android-sdk-preview-license && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "tools" >/dev/null 2>&1 && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" >/dev/null 2>&1 && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}" >/dev/null 2>&1 && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;android;m2repository" >/dev/null 2>&1 && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;google;google_play_services" >/dev/null 2>&1 && \
    echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;google;m2repository" >/dev/null 2>&1 && \
    touch local.properties && \
    echo "sdk.dir=${ANDROID_HOME}" >> local.properties && \
    echo "ndk.dir=${ANDROID_NDK_HOME}" >> local.properties

# Ruby install
ENV RUBY_MAJOR=2.5 \
    RUBY_VERSION=2.5.3 \
    RUBYGEMS_VERSION=2.7.8 \
    BUNDLER_VERSION=1.17.1 \
    GEM_HOME='/usr/local/bundle' \
    BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME" \
    BUILD_DEPS='bison dpkg-dev libgdbm-dev ruby' \
    PATH="$GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH"

RUN mkdir -p /usr/local/etc && \
    apt-get update && \
    apt-get --quiet install -y --no-install-recommends  ca-certificates curl netbase gnupg dirmngr wget \
        autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick \
        libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libevent-dev libffi-dev libgdbm-dev libgeoip-dev \
        libglib2.0-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev libncurses5-dev \
        libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev \
        libxml2-dev libxslt-dev libyaml-dev make patch xz-utils zlib1g-dev vim \
        $BUILD_DEPS && \
    rm -rf /var/lib/apt/lists/*
ADD gemrc /usr/local/etc/gemrc
RUN wget -nv -q -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" && \
    mkdir -p /usr/src/ruby && \
    tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 && \
    rm ruby.tar.xz
WORKDIR /usr/src/ruby
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
RUN apt-get update && \
        apt-get --quiet install -y --no-install-recommends

RUN { \
        echo '#define ENABLE_PATH_CHECK 0'; \
        echo; \
        cat file.c; \
    } > file.c.new && \
    mv file.c.new file.c && \
    autoconf && \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" && \
    ./configure \
         --silent \
         --build="$gnuArch" \
         --disable-install-doc \
         --enable-shared && \
    make --silent -j "$(nproc)" && \
    make --silent install && \
    apt-get --quiet purge -y --auto-remove $BUILD_DEPS && \
    rm -r /usr/src/ruby

RUN gem update --system "$RUBYGEMS_VERSION" && \
    gem install bundler --version "$BUNDLER_VERSION" --force && \
    rm -r /root/.gem/ && \
    mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

# ——————————
# Install Node and global packages
# ——————————
ENV NODE_VERSION 8.11.3
RUN cd && \
  wget -q http://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz && \
  tar -xzf node-v${NODE_VERSION}-linux-x64.tar.gz && \
  mv node-v${NODE_VERSION}-linux-x64 /opt/node && \
  rm node-v${NODE_VERSION}-linux-x64.tar.gz
ENV PATH ${PATH}:/opt/node/bin

# ——————————
# Install Basic React-Native packages
# ——————————
RUN npm install react-native-cli rnpm yarn -g

CMD [ "irb" ]
