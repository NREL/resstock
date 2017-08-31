#!/bin/bash

# Temporary fix; should be done by OpenStudio 2.0.6 installer
apt-get update
apt-get install -y libglu1-mesa libjpeg8 libfreetype6 libdbus-glib-1-2 libfontconfig1 libsm6 libxi6

export CI=true
export CIRCLECI=true
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd /OpenStudio-BuildStock

rm -f Gemfile.lock
bundle install

#rake update_measures

# Run a specific set of tests on each node.
# Test groups are defined in the Rakefile.
# Each group must have a total runtime less
# than 2 hrs.
case $CIRCLE_NODE_INDEX in
  0)
    # We currently only use one node to make Coveralls happy.
    rake test:all
    ;;
  #1)
  #  ;;
  #2)
  #  ;;
  #3)
  #  ;;
  *)
esac