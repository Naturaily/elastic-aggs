#!/bin/bash -e

bundle check || bundle install
# yarn check || yarn install

if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

bundle exec rails s -p 3000 -b 0.0.0.0
