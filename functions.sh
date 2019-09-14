CACHE_FOLDER="$HOME/.cache/custom-bash-functions"

_addTaskIDtoMessage () {
  TASK_ID_REGEX="\/(TD-[0-9]+)"

  if [[ "$(git branch | grep \* | cut -d ' ' -f2)" =~ $TASK_ID_REGEX ]]
  then
    echo "${match[1]} # $1"
    return 0
  fi

  echo $1
}

_saveCache () {
  mkdir -p "$CACHE_FOLDER"

  FILE="$CACHE_FOLDER/$1"

  rm -f "$FILE"
  touch "$FILE"

  echo "$2" >> "$FILE"
}

_readCache () {
  cat "$CACHE_FOLDER/$1"
}

docker-kill-all () {
  docker stop $(docker ps -a -q);
  docker rm $(docker ps -a -q);
}

gitc () {
  git add .
  msg=$(echo "$*" | tr -s ' ')
  git commit -m "$(_addTaskIDtoMessage $msg)"
}

gitp () {
  has_been_moved=false
  if [ -d .node_modules ]; then
    mv .node_modules node_modules
    has_been_moved=true
  fi

  if [ -n "$1" ]; then
    gitc $*;
  fi

  git push --set-upstream origin "$(git branch | grep \* | cut -d ' ' -f2)";

  if [ "$has_been_moved" = true ] && [ -d node_modules ]; then
    mv node_modules .node_modules 2>/dev/null || true
  fi
}

gitpr () {
  if [ -n "$1" ]; then
    gitp $*;
  fi

  remote_url="$(git config --local remote.origin.url)"
  branch_name="$(git branch | grep \* | cut -d ' ' -f2)"
  if [[ $remote_url =~ ':([^\.]+)' ]]; then
    xdg-open "https://bitbucket.org/${match[1]}/pull-requests/new?source=$branch_name&dest=development" &> /dev/null
  fi
}

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

# Create a new branch
# USAGE:
#   gcreate [f|feature, b|bugfix, -|cache] [task id] message...
#   gcreate f 1502 alert user on error
#     -> feature/TD-1502-alert-user-on-error
#   gcreate -
#     -> last branch created
gcreate () {
  if [ "$1" = "-" ]; then
    gco -b "$(_readCache gcreate)"
    return 0
  fi

  BRANCH_TYPE="${1:0:1}"
  if [ "$BRANCH_TYPE" = "f" ]; then
    BRANCH_TYPE="feature"
  elif [ "$BRANCH_TYPE" = "b" ]; then
    BRANCH_TYPE="bugfix"
  elif [ "$BRANCH_TYPE" = "h" ]; then
    BRANCH_TYPE="hotfix"
  else
    echo "Specify a branch type: feature, bugfix or hotfix"
    return 1
  fi

  shift

  TASK_ID_REGEX="([0-9]+)"
  TASK_ID=""
  if [[ "$1" =~ $TASK_ID_REGEX ]]; then
    TASK_ID="TD-${match[1]}"
  else
    TASK_ID="UR"
  fi

  shift

  BRANCH_NAME="$BRANCH_TYPE/$TASK_ID"
  if [ -n "$*" ]; then
    BRANCH_NAME="$BRANCH_NAME-$(echo "$*" | tr -s ' ' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]')"
  fi

  _saveCache "gcreate" "$BRANCH_NAME"
  gco -b $BRANCH_NAME
}

gcos () {
  branch_name=$(git branch -a | grep $@ | head -n 1 | sed 's/ //g')

  if [ -z $branch_name ]; then
    git fetch
    branch_name=$(git branch -a | grep $@ | head -n 1 | sed 's/ //g')
    if [ -z $branch_name ]; then
      echo "No branch found for $@"
      return 1
    fi
  fi

  REMOTE_REGEX="^(remotes/[^/]*/)"
  if [[ "$branch_name" =~ $REMOTE_REGEX ]]; then
    branch_name="${branch_name//${match[1]}/}"
  fi

  gco $branch_name
}

ddos () {
  URL=$1
  TIMES=$2

  for ((n=0; n<$TIMES; n++))
  do
    wget $URL
  done
}

pipu ()  {
  pip $@ --user
}