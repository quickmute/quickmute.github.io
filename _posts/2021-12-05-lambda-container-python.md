# Prereqs
- Install Docker Desktop

# Create Docker Image
1. Create a new file: `Dockerfile`
2. Create a new `app` directory
3. Create a new file under this directory, `app.py`
<script src="https://gist.github.com/quickmute/166f67f723ebe54a56d88d8fed1c65d8.js"></script>
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
```
$body = '{"Name":"Buddy"}'
$output = Invoke-WebRequest -Method Post -Body $body -Uri "http://localhost:9000/2015-03-31/functions/function/invocations"
$output.RawContent

```

2. You should see this as your output
![Powershell Output](/assets/docker_build_step4.png)
3. You should see this in your App
![Docker App Output](/assets/docker_build_step5.png)

# References
- [Lambda Container Support](https://aws.amazon.com/blogs/aws/new-for-aws-lambda-container-image-support/)
- [Lambda Runtime Interface Emulator](https://github.com/aws/aws-lambda-runtime-interface-emulator/)
