#!/usr/bin/env bash
set -e
DIR="security/mtls"
mkdir -p "$DIR"
echo "🔐 Generating mTLS materials in $DIR"
openssl genrsa -out "$DIR/ca.key" 4096
openssl req -x509 -new -nodes -key "$DIR/ca.key" -sha256 -days 3650 -out "$DIR/ca.crt" -subj "/CN=SOVEREIGN-CORE-CA"
openssl genrsa -out "$DIR/node.key" 2048
openssl req -new -key "$DIR/node.key" -out "$DIR/node.csr" -subj "/CN=SOVEREIGN-CORE-NODE"
openssl x509 -req -in "$DIR/node.csr" -CA "$DIR/ca.crt" -CAkey "$DIR/ca.key" -CAcreateserial -out "$DIR/node.crt" -days 365
echo "✅ Done"
