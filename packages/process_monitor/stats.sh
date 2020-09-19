#!/bin/bash

echo cpu: $(top -p$1 -b -n1 | grep "dart" | head -1 | awk '{print $9}') mem: $(top -p$1 -b -n1 | grep "dart" | head -1 | awk '{print $10}')