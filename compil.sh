#!/bin/bash
make
IFS='.' read -ra ADDR <<< "$1"
./myc $1 ${ADDR}.h ${ADDR}.c

gcc -o ${ADDR} ${ADDR}.c
./${ADDR}
