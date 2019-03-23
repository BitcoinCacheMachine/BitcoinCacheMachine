#!/bin/bash

echo "entrypoint for electrs"

cargo run --release -- -vvv --timestamp --db-dir /root/.electrs/db
