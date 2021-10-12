#!/bin/bash

cd `dirname $0`/../

zip -x".gitignore" -x"README.md" -x"LICENSE" -x".git/*" -r sm-force-lock-class_0.0.0.zip .
