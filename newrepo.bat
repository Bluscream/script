git init
gh repo create %1 --public --source=. --remote=upstream
git add .
git commit -m "initial commit"
git push --set-upstream upstream master