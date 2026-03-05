#!/usr/bin/env bash
cd ~/sovereign-core
export PYTHONPATH=$PWD
uvicorn dashboard.app:app --host 0.0.0.0 --port 8080
