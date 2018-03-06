#!/bin/bash

bundle exec sidekiq -C config/sidekiq.yml -r . -P tmp/pids/sidekiq.pid
