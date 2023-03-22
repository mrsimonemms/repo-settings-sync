#!/usr/bin/env bash

set -eo pipefail

#############
# Variables #
#############

CMD="${1:-}"
TMP_DIR="/tmp/repo-settings-sync"

###########
# Scripts #
###########

mkdir -p "${TMP_DIR}"

apply_repo_update() {
  TOKEN="${1}"
  REPO="${2}"
  SETTINGS="${3}"

  curl -sfL \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}" \
    -d "${SETTINGS}"
}

get_all_repos() {
  TOKEN="${1}"

  page=1
  finished=false

  dir="${TMP_DIR}/repos"
  rm -Rf "${dir}"
  mkdir -p "${dir}"

  until [ "${finished}" = "true" ]
  do
    result=$(curl -sfL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/repos?page=${page}&affiliation=owner")

    count=$(echo "${result}" | jq '. | length')

    if [ "${count}" -eq 0 ]; then
      finished=true
    else
      echo "${result}" | jq -r > "${dir}/${page}.json"
    fi

    ((page++))
  done

  jq -s add ${dir}/*.json | jq -Mcr 'to_entries | map(select(.value.archived == false) | select(.value.disabled == false) | .value.full_name)'
}

get_file_from_repo() {
  TOKEN="${1}"
  REPO="${2}"
  FILE_PATH="${3}"

  curl -sfL \
    -H "Accept: application/vnd.github.raw" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/contents/${FILE_PATH}"
}

############
# Commands #
############

case "${CMD}" in
  apply_repo_update )
    apply_repo_update "${2}" "${3}" "${4}" # Token, repo, settings
    ;;
  get_all_repos )
    get_all_repos "${2}" # Token
    ;;
  get_file_from_repo )
    get_file_from_repo "${2}" "${3}" "${4}" # Token, repo, file path
    ;;
  * )
    echo "Unknown command: ${CMD}"
    exit 1
    ;;
esac
