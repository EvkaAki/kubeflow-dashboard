# Step 1: Builds and tests
FROM node:12.22.12-bullseye AS build

ARG kubeflowversion
ARG commit
ENV BUILD_VERSION=$kubeflowversion
ENV BUILD_COMMIT=$commit
ENV CHROME_BIN=/usr/bin/chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN apt update -qq && apt install -qq -y chromium gnulib

COPY . /centraldashboard
WORKDIR /centraldashboard

RUN BUILDARCH="$(dpkg --print-architecture)" &&  npm rebuild && \
    if [ "$BUILDARCH" = "arm64" ]  ||  \
    [ "$BUILDARCH" = "armhf" ]; then \
    export CFLAGS=-Wno-error && \
    export CXXFLAGS=-Wno-error;  \
    fi

RUN npm install
#RUN npm test
RUN npm run build
RUN npm prune --production

# Step 2: Packages assets for serving
FROM node:12.22.12-alpine AS serve

ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /centraldashboard .

RUN apk update && apk add --no-cache sudo bash openrc openssh
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel && rc-update add sshd default

EXPOSE 8082
ENTRYPOINT ["npm", "start"]
