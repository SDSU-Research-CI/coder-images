#!/bin/env bash

/opt/code-server/bin/code-server --auth none --port 13337 --bind-addr 0.0.0.0 > /tmp/code-server.log 2>&1

