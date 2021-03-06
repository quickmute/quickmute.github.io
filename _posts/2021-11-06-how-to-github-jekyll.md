---
layout: post
author: Hyon
---
# Install git
1. Download [git](https://git-scm.com/)
2. Configure your git (you will get prompted for credential when you try to commit later)
   - `git config --global user.name "myusername"`
   - `git config --global user.email "myemailaddress@email.com"`
3. Clone your existing repo for your website
   - `cd c:\mygithub`
   - `git clone https://github.com/quickmute/quickmute.github.io.git`

# Install Ruby with devkit
1. Download [Ruby](https://rubyinstaller.org/downloads/)
2. Click on `Start Command Prompt with Ruby` from your Start Menu

# Install Jekyll
1. Use the Ruby command prompt
   `gem install bundler jekyll`
2. Go to the parent path where you cloned the repo
   `cd c:\mygithub`
3. Create your site
   `jekyll new quickmute.github.io`

# Build and deploy your site
1. Go into your directory
   `cd quickmute.github.io`
2. Build the site
   `jekyll build`
3. Stage and Push the changes
   - `git add .`
   - `git commit -m "my changes"`
   - `git push`

# Write and publish a post
1. Go to `_posts` directory
2. Create a new file that looks something like this `YYYY-MM-DD-title.md` (replace YYYY-MM-DD with today's date)
3. Edit and save your new markdown file
4. Go up to parent directory
4. Re-build the site
   `jekyll build`
5. Re-publish the site
   - `git add .`
   - `git commit -m "new post"`
   - `git push`


# Journey Continues
Now follow this instructions to customize your site. [Jekyll Step 01](https://jekyllrb.com/docs/step-by-step/01-setup/)