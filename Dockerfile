FROM openjdk:8-jdk

# 作成者情報
MAINTAINER toshi <toshi@toshi.click>

# set Env
ENV ANDROID_SDK_TOOLS "3859397"
ENV ANDROID_BUILD_TOOLS "26.0.2"
ENV ANDROID_COMPILE_SDK "26"
ENV SDK_ROOT "/sdk"

RUN apt-get --quiet update --yes \
    && apt-get --quiet install --yes wget tar unzip lib32stdc++6 lib32z1 \
    && wget --quiet --output-document=android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS}.zip \
    && unzip -qq android-sdk.zip -d ${SDK_ROOT} \
    && mkdir -p /root/.android \
    && touch /root/.android/repositories.cfg \
    && mkdir -p ${SDK_ROOT}/licenses \
    && echo -e "\n8933bad161af4178b1185d1a37fbf41ea5269c55" > ${SDK_ROOT}/licenses/android-sdk-license \
    && echo -e "\n84831b9409646a918e30573bab4c9c91346d8abd" > ${SDK_ROOT}/licenses/android-sdk-preview-license \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "tools" >/dev/null 2>&1 \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "platforms;android-${ANDROID_COMPILE_SDK}" >/dev/null 2>&1 \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "build-tools;${ANDROID_BUILD_TOOLS}" >/dev/null 2>&1 \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;android;m2repository" >/dev/null 2>&1 \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;google;google_play_services" >/dev/null 2>&1 \
    && echo y | ${SDK_ROOT}/tools/bin/sdkmanager "extras;google;m2repository" >/dev/null 2>&1 \
    && export ANDROID_HOME=${SDK_ROOT} \
    && export ANDROID_NDK_HOME=${SDK_ROOT}/ndk-bundle/ \
    && export PATH=$PATH:${SDK_ROOT}/platform-tools/ \
    && touch local.properties \
    && echo "sdk.dir=${ANDROID_HOME}" >> local.properties \
    && echo "ndk.dir=${ANDROID_NDK_HOME}" >> local.properties \
    && chmod +x ./gradlew

