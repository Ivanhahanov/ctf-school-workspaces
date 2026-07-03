#!/bin/bash
# Start Jupyter Notebook locally (no token, localhost only — single-user container)
# and open it in Firefox. Runs fully offline.
cd "$HOME" || exit 1
jupyter notebook \
  --no-browser --ip=127.0.0.1 --port=8888 \
  --NotebookApp.token='' --NotebookApp.password='' \
  >/tmp/jupyter.log 2>&1 &
# Wait for the server, then open the browser.
for i in $(seq 1 20); do
  curl -fsS http://127.0.0.1:8888/ >/dev/null 2>&1 && break
  sleep 0.5
done
exec firefox-esr "http://127.0.0.1:8888/tree"
