@echo off 

:: Author : ModelZ
:: Copyright (c) SOmapait.com
:: Script: Lazy Git Script

git add .
echo please add commit text: 
set /p text=
set all="%DATE% : %text%"
git commit -m %all% 
git push