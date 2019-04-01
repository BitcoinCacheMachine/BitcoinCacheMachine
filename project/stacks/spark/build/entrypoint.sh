#!/bin/bash

set -Eeuo pipefail

spark-wallet -i 0.0.0.0 --no-tls --print-key  --print-qr --pairing-qr --pairing-url
