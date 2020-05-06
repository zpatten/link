#/usr/bin/env bash
set -x

#yard server -m ruby-core2.6 .yardoc -b 0.0.0.0 --fork
#yard server -m gems .yardoc-gems -b 0.0.0.0 --fork
yard server -m ruby-core2.6 .yardoc-ruby stdlib .yardoc-stdlib -b 0.0.0.0 --gems --debug 
