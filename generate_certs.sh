#!/bin/bash

mkdir -p ca blue_namespace red_namespace

echo "🔐 Generating CA..."

# CA
openssl genrsa -out ca/ca.key 2048
openssl req -x509 -new -key ca/ca.key -out ca/ca.crt -days 365 \
  -subj "/C=IN/ST=Maharashtra/L=Mumbai/O=MiniProject/OU=CA/CN=RootCA"

echo "🖥️ Generating Server Certificate..."

# Server
openssl genrsa -out blue_namespace/server.key 2048
openssl req -new -key blue_namespace/server.key -out blue_namespace/server.csr \
  -subj "/C=IN/ST=Maharashtra/L=Mumbai/O=MiniProject/OU=Server/CN=blue-server"

openssl x509 -req -in blue_namespace/server.csr \
  -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
  -out blue_namespace/server.crt -days 365

echo "💻 Generating Client Certificate..."

# Client
openssl genrsa -out red_namespace/client.key 2048
openssl req -new -key red_namespace/client.key -out red_namespace/client.csr \
  -subj "/C=IN/ST=Maharashtra/L=Mumbai/O=MiniProject/OU=Client/CN=red-client"

openssl x509 -req -in red_namespace/client.csr \
  -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
  -out red_namespace/client.crt -days 365

echo "📦 Copying CA certificate..."

# Copy CA cert
cp ca/ca.crt blue_namespace/
cp ca/ca.crt red_namespace/

echo "✅ Done! Certificates generated."