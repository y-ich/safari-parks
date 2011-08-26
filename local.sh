#!/bin/bash
bundle exec rake jobs:work &
bundle exec rackup
