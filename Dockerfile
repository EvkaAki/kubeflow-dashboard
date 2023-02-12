# Step 1: Builds and tests
FROM node:12.18.3-alpine AS build

ARG kubeflowversion
ARG commit
ENV BUILD_VERSION=$kubeflowversion
ENV BUILD_COMMIT=$commit
ENV CHROME_BIN=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN apk add -X http://nl.alpinelinux.org/alpine/edge/main -u alpine-keys --allow-untrusted
RUN apk add -X http://nl.alpinelinux.org/alpine/edge/community -u alpine-keys --allow-untrusted

# Installs latest Chromium package and configures environment for testing
RUN apk update && apk upgrade
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
RUN echo @edge http://nl.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories
RUN apk add --no-cache bash chromium@edge nss@edge \
    freetype@edge \
    harfbuzz@edge \
    ttf-freefont@edge \
    libstdc++@edge

RUN if [ "$(uname -m)" = "aarch64" ]; then \
        apk update && apk upgrade && \
        apk add --no-cache python2 make g++@edge; \
    fi

COPY . /centraldashboard
WORKDIR /centraldashboard

RUN npm rebuild && \
    if [ "$(uname -m)" = "aarch64" ]; then \
        export CFLAGS=-Wno-error && \
        export CXXFLAGS=-Wno-error && \
        npm install; \
    else \
        npm install; \
    fi && \
    npm test && \
    npm n && \
    npm prune --production

# Step 2: Packages assets for serving
FROM node:12.18.3-alpine AS serve

ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /centraldashboard .

#RUN apk update && apk add --no-cache sudo bash openrc openssh
#RUN echo 'PermitRootLogin yes' >> etc/ssh/sshd_config
#RUN echo 'PasswordAuthentication yes' >> etc/ssh/sshd_config
#RUN mkdir -p /run/openrc && touch /run/openrc/softlevel && rc-update add sshd default

EXPOSE 8082
ENTRYPOINT ["npm", "start"]
