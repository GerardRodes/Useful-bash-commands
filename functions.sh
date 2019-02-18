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
  if [ -n "$1" ]; then
    gitc $*;
  fi

  git push --set-upstream origin "$(git branch | grep \* | cut -d ' ' -f2)";
}

gitpr () {
  if [ -n "$1" ]; then
    gitc $*;
  fi
  branch_name="$(git branch | grep \* | cut -d ' ' -f2)"
  git push --set-upstream origin $branch_name

  remote_url="$(git config --local remote.origin.url)"
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
  else
    echo "Specify a branch type, feature or bugfix"
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

gitc_r () {
  mv .node_modules node_modules 2>/dev/null || true
  gitc $*
  mv node_modules .node_modules 2>/dev/null || true
}

gitp_r () {
  mv .node_modules node_modules 2>/dev/null || true
  gitp $*
  mv node_modules .node_modules 2>/dev/null || true
}