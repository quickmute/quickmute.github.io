---
layout: post
title:  "Using Terraform Docker Provider with remote Docker Daemon"
date:   2021-12-27 23:11:29 -0500
categories: aws ec2 docker terraform
---
# Introduction
This is a continuation of [previous post]({% post_url 2021-12-26-docker-engine-server %}). This will use the same EC2 server, secure it using our own Server and Client certificates, and use it via Terraform Docker provider. 

# Create directory to house keys
  ```bash
  mkdir -pv /var/docker
  ```
# Create Certificate Authority Keys
  1. Private Key
     ```bash
     sudo openssl genrsa -aes256 -out ca-key.pem 4096
     ```
  2. Public Key
     ```bash
     sudo openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
     ```

![Server Cert](/assets/server_cert.jpeg)

# Create Server Cert
  1. Private Key
     ```bash
     sudo openssl genrsa -out server-key.pem 4096
     ```
  2. Certificate Signing Request
     - Generate CSR
       ```bash
       sudo openssl req -subj "/CN=myserver.com" -sha256 -new -key server-key.pem -out server.csr
       ```
     - Set SAN
       ```bash
       sudo echo subjectAltName = DNS:myserver.com,IP:111.111.111.111,IP:127.0.0.1 >> extfile.cnf
       ```
     - Set Key Usage Attribute
      ```bash
      sudo echo extendedKeyUsage = serverAuth >> extfile.cnf
      ```
  3. Server Certificate
     ```bash
     sudo openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf
     ```

# Create Client Cert
  1. Private Key
     ```
     sudo openssl genrsa -out client-key.pem 4096
     ```
  2. Certificate Signing Request
     - Generate CSR
       ```
       sudo openssl req -subj '/CN=client' -new -key client-key.pem -out client.csr
       ```
     - Set Key Usage Attribute
       ```
       sudo echo extendedKeyUsage = clientAuth > extfile-client.cnf
       ```
  3. Client Cert (Public Key)
     ```
     sudo openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -extfile extfile-client.  cnf
     ```

![Client Cert](/assets/client_cert.jpeg)

# Set permissions 
  - Keys
    ```
    sudo chmod -v 0400 ca-key.pem client-key.pem server-key.pem
    ```
  - Certs
    ```
    sudo chmod -v 0444 ca.pem server-cert.pem client-cert.pem
    ```
# Move certs
  1. More all server certs to `/var/docker` folder
  2. Move all client certs to client machine under `~/.docker` directory

# Set Docker daemon to run in secure mode
  - Command line method
    ```bash
    sudo dockerd --debug --tls=true --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem --host tcp://0.0.0.0:2376
    ```
  - Using daemon.json config file
    1. Create a file at `/etc/docker/daemon.json`
    2. Insert following
       ```
       {
          "debug": true,
          "tls": true,
          "tlscacert": "/var/docker/ca.pem",
          "tlscert": "/var/docker/server-cert.pem",
          "tlskey": "/var/docker/server-key.pem",
          "hosts": ["fd://","unix:///var/run/docker.sock","tcp://0.0.0.0:2376"]
       }
       ```
    4. Update systemd to listen on this port from localhost
       ```
       sudo systemctl edit docker.service
       ```
    5. Update as follows
       ```
       [Service]
       ExecStart=
       ExecStart=/usr/bin/dockerd
       ```
    6. Restart Service
       ```
       sudo systemctl daemon-reload
       sudo systemctl restart docker.service
       ```
  
# Use Docker (client) to run in secure mode
  - Move your keys to .docker directory of your profile
    ```dos
    mkdir -pv ~/.docker
    
    cp -v {ca,cert,key}.pem ~/.docker
    ```
  - Command line method
    ```dos
    cd ~/.docker
  
    docker --tlsverify --tlscacert=ca.pem --tlscert=client-cert.pem --tlskey=client-key.pem --host tcp://111.111.111.111.183:2376 version
    ```
  - Using .docker directory to hold your keys
    ```powershell
    $DOCKER_HOST=tcp://myserver.com:2376 DOCKER_TLS_VERIFY=1
  
    docker version
    ```

# Use Terraform Provider to connect to Docker daemon
  1. Define the docker provider
     ```js
     terraform {
       required_providers {
         docker = {
         source  = "kreuzwerker/docker"
         version = "2.15.0"
         }
       }
     }
     ```
  2. Define the docker host server information
      ```js
      provider "docker" {
        host = "tcp://111.111.111.111:2376"
        ca_material   = file(pathexpand("~/.docker/ca.pem"))
        cert_material = file(pathexpand("~/.docker/client-cert.pem"))
        key_material  = file(pathexpand("~/.docker/client-key.pem"))
      }
      ```
  3. Test by creating a ubuntu container
      ```js
      resource "docker_image" "ubuntu" {
        name = "ubuntu:latest"
      }
      ```