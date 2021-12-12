# Prereqs
- Install Docker Desktop

# Create Docker Image
1. Create a new file: `Dockerfile`
<script src="https://gist.github.com/quickmute/dbc248a30d8f63b3d9e1d5b105dcef87.js"></script>
   - If you don't install the Lambda Runtime Interface Emulator, then this App will fail when you do `docker run` from local or ECS. I think Lambda Runtime Interface Client is trying to talk to Lambda and without Lambda or Emulator it'll fail.   
   - In the `cmd` block, your reference must match the FILENAME.DEFINITION exactly. So in this case, the name of file we'll create is `app.py` and the definition is `handler`. 
2. Create a new `app` directory
3. Create a new file under this directory, `app.py`
<script src="https://gist.github.com/quickmute/166f67f723ebe54a56d88d8fed1c65d8.js"></script>
In this python code, we print the payload which will contain the name and the version of python. 
4. Go to the directory where this `Dockerfile` is located
5. Build it using this command
```
docker build -t myfunction:latest .
```
![Docker Build](/assets/docker_build_step2.png)
6. You should see it inside your Docker Desktop
![New Image](/assets/docker_build_step3.png)
# Deploy the container
1. Run it, expose port 9000
```
docker run -d -p 9000:8080 myfunction:latest
```

# Test it (Powershell)
1. Run this 
<script src="https://gist.github.com/quickmute/52725d643c9169a9ac8180ea499175bb.js"></script>
Change the name of the person to see what happens. You can also change the keyname to see what happens. 
2. You should see this as your output
![Powershell Output](/assets/docker_build_step4.png)
3. You should see this in your App
![Docker App Output](/assets/docker_build_step5.png)

# References
- [Lambda Container Support](https://aws.amazon.com/blogs/aws/new-for-aws-lambda-container-image-support/)
- [Lambda Runtime Interface Emulator](https://github.com/aws/aws-lambda-runtime-interface-emulator/)
- [Lambda Container Tutorial Files](https://github.com/quickmute/aws_lambda_container_tutorial)