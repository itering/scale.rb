FROM ruby:2.6-alpine3.11

ENV BUILD_PACKAGES curl-dev build-base

RUN apk update && \
    apk upgrade && \
    apk add git curl $BUILD_PACKAGES

WORKDIR /usr/src/app

COPY . .

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $HOME/.cargo/env && \
    export RUSTFLAGS='-C target-feature=-crt-static' && \
    make

ENV RUSTFLAGS='-C target-feature=-crt-static'
ENV PATH=/root/.cargo/bin:$PATH

RUN gem install bundler:2.2.13 && \
    bundle install && \
    rake install:local

CMD ["sh"]
