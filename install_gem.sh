#!/usr/bin/env bash

cd $(dirname $0)
rake build
gem install $(ls -tr pkg/*.gem | tail -n 1)
