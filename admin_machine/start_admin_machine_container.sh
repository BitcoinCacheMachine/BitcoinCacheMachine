#!/bin/bash

docker build -t bcmadmin .

docker run --name bcmadmin -it --device=/dev/bus/usb/001/011 bcmadmin
