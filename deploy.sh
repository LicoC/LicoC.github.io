hexo generate
cp -R public/* .deploy/Licoc.github.io
cd .deploy/Licoc.github.io
git add .
git commit -m “update”
git push origin master
