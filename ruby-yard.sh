#/usr/bin/env bash
set -x

#yardoc -b .yardoc-ruby -o doc-ruby /home/zpatten/.rvm/src/ruby-2.6.3/*.c
rm -rf .yardoc-stdlib doc-stdlib
yardoc -b .yardoc-stdlib -o doc-stdlib /home/zpatten/.rvm/src/ruby-2.6.3/lib/*.rb
