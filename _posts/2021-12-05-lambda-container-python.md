# Prereqs
- Install Docker Desktop

# Create Docker Image
1. Create a new file: Dockerfile
2. Create a new app directory
3. Create a new file under this directory, `app.py`
4. Go to the directory where this file is located
5. Build it using this command
```
docker build -t myfunction:latest .
```

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


# References
- [Lambda Container Support](https://aws.amazon.com/blogs/aws/new-for-aws-lambda-container-image-support/)
- [Lambda Runtime Interface Emulator](https://github.com/aws/aws-lambda-runtime-interface-emulator/)
