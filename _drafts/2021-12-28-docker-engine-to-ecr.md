---
layout: post
title:  "Pushing Container images from EC2 to ECR"
date:   2021-12-28 23:11:29 -0500
categories: AWS EC2 Docker Terraform ECR
---
# Introduction
This is a continuation of [previous post]({% post_url 2021-12-27-terraform-docker-engine %}). This will automate the process of syncing the engine server's docker images to your ECR. We'll use inotify-tool and systemctl sync the images whenever local `repositories.json` is updated.

# References
  - [Systemctl Configuration](https://www.howtogeek.com/687970/how-to-run-a-linux-program-at-startup-with-systemd/) 

# Prereq
  - Create a new ECR Repo: I'll be calling mine `99999999999.dkr.ecr.us-east-2.amazonaws.com/my_images`
  - Use Instance Profile with permission to your ECR repository
  - Install AWS CLI

# Install AWS CLI
  1. log into your EC2 instance
  2. Run following
     ```
     sudo apt install awscli
     ```
  3. Verify access
     ```
     aws ecr describe-repositories --region us-east-2
     aws ecr list-images --repository-name my_images --region us-east-2
     ```
     If you don't have access to do either tasks above, you'll need to fix your Instance Profile
  4. If you haven't done so already, you can create the repo now
     ```
     create-repository --repository-name 'my_images' 
     ```

# Push your local image to ECR
  1. Get Credential
     ```
     aws ecr get-login-password --region us-east-2 | docker login -u AWS --password-stdin 999999999999.dkr.ecr.us-east-2.amazonaws.com
     ```
  2. Tag your image you want to push to ECR
     ```
     docker tag hello-world:latest 999999999999.dkr.ecr.us-east-2.amazonaws.com/my_images:latest
     ```
  3. Push it
     ```
     docker push 999999999999.dkr.ecr.us-east-2.amazonaws.com/my_images:latest
     ```
  4. Delete it, you don't need it anymore
     ```
     docker image rm 999999999999.dkr.ecr.us-east-2.amazonaws.com/my_images:latest
     ```

# Script it
[Shell Script at github repo](https://github.com/quickmute/docker-ecr-image-sync/blob/main/sync_ecr.sh)

# Automate it using systemctl and inotify-tools
  1. Install inotify-tools: `sudo apt-get install inotify-tools`
  2. Drop this script to `/usr/local/bin/syncecr.sh`
     <script src="https://gist.github.com/quickmute/5bee93a4f5176c0ed0e7b6979ba8df54.js"></script>
     This script runs `inotifywait` command that calls the script from the previous section when it is triggered
  3. Update permission via `sudo chmod 775`
  4. Create service unit file
     ```
     sudo vi /etc/systemd/system/syncecr.service
     ```
     Paste this
     ```
     [Unit]
     Description=Sync ECR Service

     Wants=network.target
     After=syslog.target network-online.target

     [Service]
     Type=simple
     ExecStart=/usr/local/bin/syncecr.sh
     Restart=on-failure
     RestartSec=10
     KillMode=process

     [Install]
     WantedBy=multi-user.target
     ```
     Change permission
     ```
     sudo chmod 640 /etc/systemd/system/syncecr.service
     ```
  5. Reload unit file definition
     ```
     sudo systemctl daemon-reload
     ```
  6. Enable it to load on startup
     ```
     sudo systemctl enable syncecr
     ```
  7. Start the service
     ```
     sudo systemctl start syncecr
     ```
  8. Now create a new image. You should see a new Repo in your ECR. You can also see the status in the systemctl status.
     ```
     sudo systemctl status syncecr
     ```
  9. Now kill the service, this isn't our final solution...
     ```
     sudo systemctl stop syncecr
     sudo systemctl disable syncecr
     ```

# Automate it using LogWatch
  1. sudo apt-get install logwatch
  2. I choose localonly for mail delivery, your situation may differ
  3. sudo mkdir /var/cache/logwatch
  4. sudo cp /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/
  5. sudo logwatch --detail Low --range today

# Automate it using swatchdog
https://www.linuxtoday.com/blog/swatch-log-file-watcher/

https://manpages.debian.org/testing/swatch/swatchdog.1p.en.html

  1. sudo apt-get install swatch
  2. sudo vi /etc/swatch.conf
  3. sudo journalctl -fu docker.service
  ```
  watchfor /dockerd.*Calling DELETE.*images/
      echo
      quit

  watchfor /dockerd.*Calling POST.*images.*create/
      echo
      quit
  ```
  4. swatchdog --config-file=/etc/swatch.conf
  5. sudo vi /etc/init.d/swatch
  6. 
  ```
  #!/bin/sh
  # Simple Log Watcher Program

  case "$1" in
  'start')
	  	/usr/bin/swatch --daemon --config-file=/etc/swatch.conf --tail-file=/var/log/auth.log --pid-file=/var/run/swatch.pid
		;;
  'stop')
		PID=`cat /var/run/swatch.pid`
		kill $PID
		;;
  *)
		echo "Usage: $0 { start | stop }
		;;
  esac
  exit 0
  ```

