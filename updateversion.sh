#!/bin/sh
if [ "$#" != 1 ]; then
	echo "You must give me the argument 1 for environment setting."
	exit 1;
fi

deployEnv="";
if [ "$1" == "pp" ]; then
	echo "Ready to deploy app for pre-production"
	deployEnv="-preprod"
elif [ "$1" == "prod"]; then
	echo "Ready to deploy app for production"
	deployEnv=""
fi

 ## Get version string.
deployTag=$(cat .travis.yml  | grep -i -E "DEPLOY_TAG")
version=$(echo ${deployTag} | cut -d "=" -f 2 | sed 's/[a-z-]//g')
echo "Version Number: ${version}"
 ## extract version number.

 major=$(echo ${version} | cut -d "." -f 1)
 minor=$(echo ${version} | cut -d "." -f 2)
 revision=$(echo ${version} | cut -d "." -f 3)

newRevision=$(($revision + 1))
echo "update revision from ${revision} to ${newRevision}"

newVersion="${major}.${minor}.${newRevision}""${deployEnv}"

echo "... replace version ${version} to ${newVersion}"

cat .travis.yml | grep -i -E "DEPLOY_TAG"
echo "-----------> "
sed "s/$version.*/$newVersion/g" ".travis.yml" > tempXXX.yml
cat tempXXX.yml | grep -i -E "DEPLOY_TAG"
mv -f tempXXX.yml .travis.yml

echo "Ready to update new version: \"${newVersion}\""

git add .travis.yml
git commit -m "release new version ${newVersion}"
git tag ${newVersion}
git push --tags