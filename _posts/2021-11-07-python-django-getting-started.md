
1. Install Python
2. Update path to python, if necessary
3. Set execution policy (as admin), if necessary
`Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser`
4. Create venv
`python -m venv .\django\`
5. Create your project folder
`django-admin startproject mywebsite`
6. Go into your project folder
`cd mywebsite`
7. Start your service
`python manage.py runserver`
8. Browse to your site `http://127.0.0.1:8000/`