#!/bin/sh
export RAILS_ENV=production

bundle exec sidekiq
