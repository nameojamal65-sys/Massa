#!/data/data/com.termux/files/usr/bin/sh
mkdir -p "$HOME/ForgeMind_DRIVE/data/corpus"
exec forgemind serve --addr 127.0.0.1:8080 --data "$HOME/ForgeMind_DRIVE/data" --token fm_dev_token
