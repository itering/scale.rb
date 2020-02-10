FROM ruby:2.7-alpine3.11

ENV BUILD_PACKAGES curl-dev build-base

RUN echo "http://mirrors.ustc.edu.cn/alpine/v3.11/main/" > /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add git $BUILD_PACKAGES

WORKDIR /usr/src/app

COPY . .
RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ && \
    gem install bundler:1.17.3 && \
    bundle config mirror.https://rubygems.org https://gems.ruby-china.com && \
    bundle install

CMD ["./bin/console"]
