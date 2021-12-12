jekyll build
git add .
$comment = read-host "Comment"
git commit -m $comment
git push