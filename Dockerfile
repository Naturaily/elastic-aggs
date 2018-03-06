FROM ruby:2.5.0

ENV APP_ROOT /app

# nodejs version 7.x
RUN apt-get install -qq -y wget \
    && wget -qO- https://deb.nodesource.com/setup_7.x | bash -

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs cmake

# for structure.sql and pg_dump
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update -qq && \
    apt-get -qq -y install postgresql-client-9.6

WORKDIR $APP_ROOT

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

ADD . $APP_ROOT
