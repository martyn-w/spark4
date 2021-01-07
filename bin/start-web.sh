#!/usr/bin/env sh

# clear old PID
rm -f $PIDFILE

# Verify all the production gems are installed
bundle check

build=$(git log --oneline -1)
build_date=$(git log -1 --format=%cd)

if [ "${WORKER_MODE}" = "true" ]; then
    echo "Running in Worker Mode ($RAILS_ENV)"
    sleep 120
    BUILD=$build BUILD_DATE=$build_date bundle exec rake jobs:work
else
    echo "Running in App Mode ($RAILS_ENV)"

    BUILD=$build BUILD_DATE=$build_date bundle exec puma
fi
