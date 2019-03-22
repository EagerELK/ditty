FROM ruby:2.5.3-alpine3.8
LABEL maintainer: "Sergey Shkarupa <s.shkarupa@gmail.com>"

RUN apk add --no-cache \
  build-base \
  less \
  git \
  libxml2-dev \
  libxslt-dev \
  sqlite-dev \
  sqlite-doc \
  sqlite-libs \
  && gem install bundler:1.17.3

WORKDIR /usr/src/app

COPY . ./
RUN bundle install --jobs=$(nproc) --no-cache --clean
