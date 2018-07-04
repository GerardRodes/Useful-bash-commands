# aliases

## adds changes and commits
alias gitc="git add . && git commit -m"

## updates vscode to last estable version for debian x64
alias update-vscode="wget https://vscode-update.azurewebsites.net/latest/linux-deb-x64/stable -O /tmp/code_latest_amd64.deb && sudo dpkg -i /tmp/code_latest_amd64.deb"


# functions

## kills all docker containers
docker-kill-all () {
  docker stop $(docker ps -a -q);
  docker rm $(docker ps -a -q);
}

## adds changes, commits, and pushes
gitp () {
  gitc "$@" && git push;
}

## merges current branche with branch name provided as argument
gitm () {
  if [ -z "$1" ]; then
    echo "Must specify target branch"
    return 1
  fi

  if current_branch=$(git rev-parse --abbrev-ref HEAD); then
    echo "Mergin $current_branch to $1"
    git checkout $1
    git pull
    if git merge $current_branch --no-edit; then
      git push
      git checkout $current_branch
    fi
  fi
}

## replaces string recursively at specified path
replace () {
  folder=''
  old=''
  new=''

  if [ -z "$1" ]; then
    echo "Must specify old string"
    return 1
  fi
  old=$(echo "${1//\//\\/}")
  new=$(echo "${2//\//\\/}")

  if [ -z "$3" ]; then
    echo "Must specify a target path"
    return 1
  fi
  folder=$3

  echo "replacing $1 for $2 at $folder s/$old/$new/g"
  find "$folder" -type f -print0 | xargs -0 sed -i "s/$old/$new/g"
}
