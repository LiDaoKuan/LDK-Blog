#!/bin/bash

hexo clean && hexo g && hexo d

git add .
current_datetime=$(date +'%Y-%m-%d %H:%M:%S')
git commit -m "update in $current_datetime"
git push
