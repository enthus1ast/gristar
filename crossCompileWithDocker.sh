#!/bin/sh
docker build -t gristar-cross .
docker create --name extract gristar-cross
docker cp extract:/output ./binaries
docker rm extract
