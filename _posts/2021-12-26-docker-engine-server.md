---
layout: post
title:  "AWS EC2 Docker Engine Server"
date:   2021-12-26 23:11:29 -0500
categories: aws ec2 docker
---

# Introduction
Wanna run Docker Engine server on your AWS EC2 instance? This instruction will show you how. If you require additional details, please refer to below references. Everything in this document is a summary of the references.
This guide assumes following:
- Your local is on Windows 11
- Your remote is AWS EC2 instance running on Ubuntu 20.04 LTS (t2.micro)
  - Auto-Assign IPV4 address
  - Subnet has access to internet (IGW)

# References
- https://docs.docker.com/engine/install/ubuntu/
- [https://docs.docker.com/engine/install/linux-postinstall/]()
- [https://docs.docker.com/engine/security/protect-access/]()
- [https://www.cloudsavvyit.com/11185/how-and-why-to-use-a-remote-docker-host/]()
- [https://degreesofzero.com/article/ssh-tunnel-on-windows-using-putty.html]

# Prereqs
- Install Docker Desktop (do not need it running in your taskbar), you just need the Docker CLI available
- Install Putty (including PuttyGen)

# Standup EC2 Instance
  - t2.micro (this is sufficient for example)
  - Auto-Assign Public IP
  - 8GB gp2 EBS is sufficient
  - Attach Security Group, allow all TCP from your [local machine](https://www.whatismyip.com/)
  - Generate a new key pair or use existing one
  - Convert the download PEM into PPK using [PuttyGen](https://www.puttygen.com/convert-pem-to-ppk), you'll need this to Putty into your EC2 instance
  - When you log into EC2, the username you'll use is `ubuntu`

# Configure your EC2 Instance
1. Update the server
   ```
   sudo apt-get update
   ```
2. Install necessary dependencies for Docker Repository
   ```
   sudo apt-get install ca-certificates curl gnupg lsb-release
   ```
3. Trust Docker Key
   ```
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
   ```
4. Setup Docker Repository
   ```
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```
5. Update again for good measure?
   ```
   sudo apt-get update
   ```

6. Install Docker Engine
   ```
   sudo apt-get install docker-ce docker-ce-cli containerd.io
   ```
7. Check installation
   ```
   sudo docker run hello-world
   ```
   Expected output:
   ```	
   Hello from Docker!
   ```
   This message shows that your installation appears to be working correctly.
   
# Configure Docker Engine

1. Add yourself to docker group
   ```
   sudo usermod -aG docker $USER
   ```
   I found that docker group already existed, so I did not had to create it. I just added ubuntu user to it. 
2. Set service to start on boot
   ```
   sudo systemctl enable docker.service
   sudo systemctl enable containerd.service
   ```
3. Update systemd to listen on this port from localhost
   ```
   sudo systemctl edit docker.service
   ```
   Enter following:
   ```
   [Service]
   ExecStart=
   ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375
   ```
4. Restart services
   ```
   sudo systemctl daemon-reload
   sudo systemctl restart docker.service
   ```
5. Verify
   ```
   sudo netstat -lntp | grep dockerd
   ```
   You should see something like this
   ```
   tcp        0      0 127.0.0.1:2375          0.0.0.0:*               LISTEN      8507/dockerd
   ```

# Configure your local 
1. Configure Putty
   - Under Session Tab
     - enter `ubuntu@111.111.111.111` with port `22`
     - Select Never Close Window on Exist
   - Under SSH:
     - Protocol options
       - Don't start a shell or command at all
   - Auth Tab
     - Enter your private key (PPK)
   - Tunnels Tab
     - Source port: this is 2375
     - Destination port: this should be localhost:4444 <-- pick whatever port you want to use
   - Go back to Session Tab
     - Give it a save session name and click save
   - Click Open
2. Create remote [Context](https://docs.docker.com/engine/context/working-with-contexts/)
   - Create context
     ```
     docker context create my-engine --docker host="tcp://127.0.0.1:4444" --description "remote"
     ```
   - Select that context
     ```
     docker context use my-engine
     ```
3. Deploy using the engine
   - Deploy a new httpd container in the remote host
     ```
     docker run -d -p 127.0.0.1:8888:80/tcp httpd:latest
     ```
4. Verify the new container is running
   - Log back into your EC2 instance, run container list
     ```
     docker container list
     ```
     You should see the new httpd that you just deployed. 
   - Is the website working
     ```
     curl localhost:8888
     ```
     You should get back an HTML like this,
     ```
     <html><body><h1>It works!</h1></body></html>
     ```



