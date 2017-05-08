#!/bin/sh
if [ "$#" != 2 ]; then
	echo "You must give me 2 arguments for setup."
	echo "[1]: stage --> pp or prod"
	echo "[2]: branch ufo-v3 or feat-v3"
	exit 1
fi

currenctBranch=$(git branch | grep \* | cut -d ' ' -f2)

targetStage=$1
targetBranch=$2

git checkout "$targetBranch";

deployEnv=""
if [ "$targetBranch" == "ufo-v3" ]; then

	if [ "$targetStage" == "pp" ]; then
		echo "Ready to deploy app for pre-production"
		deployEnv="-preprod"
	elif [ "$targetStage" == "prod" ]; then
		echo "Ready to deploy app for production"
		deployEnv=""
	else
		echo "Stage ${targetStage} was not found! Please check it and try again!"
		exit 1
	fi

elif [ "$targetBranch" == "feat-v3" ]; then
	if [ "$targetStage" == "pp" ]; then
		echo "Ready to deploy app for pre-production"
		deployEnv="-1"
	elif [ "$targetStage" == "prod" ]; then
		echo "Ready to deploy app for production"
		deployEnv=""
	else
		echo "Stage ${targetStage} was not found! Please check it and try again!"
		exit 1
	fi
fi

function getNewVersion() {
	## Get version string.
	deployTag=$(cat .travis.yml | grep -i -E "DEPLOY_TAG")
	version=$(echo ${deployTag} | cut -d "=" -f 2 | sed 's/-.*//g' | sed 's/[a-z-]//g')
	#echo "Version Number: ${version}";

	## extract version number.
	major=$(echo ${version} | cut -d "." -f 1)
	minor=$(echo ${version} | cut -d "." -f 2)
	revision=$(echo ${version} | cut -d "." -f 3)

	newRevision=$(($revision + 1))

	#echo "update revision from ${revision} to ${newRevision}";
	newVersion="${major}.${minor}.${newRevision}${deployEnv}"

	#echo "... replace version ${version} to ${newVersion}";
	#cat .travis.yml | grep -i -E "DEPLOY_TAG";
	#echo "-----------> "
	sed "s/$version.*/$newVersion/g" ".travis.yml" >tempXXX.yml
	#cat tempXXX.yml | grep -i -E "DEPLOY_TAG"
	mv -f tempXXX.yml .travis.yml

	echo "$newVersion"
}

function checkIfTagAvailable() {
	tag=$1
	result=$(git ls-remote --tags | grep -i -E "$tag")
	if [ "$result" != "" ]; then
		echo "NO"
	else
		echo "YES"
	fi
}

function updateNewVersion() {

	newVersion = $1
	echo "Ready to update version to new version: \"${newVersion}\" with tag ${newVersion}"

	git add .travis.yml
	git commit -m "release new version ${newVersion}"
	git tag ${newVersion}
	git push origin ${targetBranch} --tags

}

## Process to get into new version
while :; do
	newVersion=$(getNewVersion)
	echo "New version will be $newVersion"

	echo "--> Check if Tag avaiable?"
	isTagAvailable=$(checkIfTagAvailable $newVersion)
	#isTagAvailable=$(checkIfTagAvailable "1.1.27-preprod")
	echo "Tag $newVersion is avaiable $isTagAvailable"

	if [ "$isTagAvailable" == "YES" ]; then
		echo "Ready to proceed!"
		updateNewVersion "${newVersion}"
		break
	fi
done
