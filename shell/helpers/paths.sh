#!/bin/bash
#
# Module/project metadata path resolution.
#

resolve_metadata_path() {
  local project_dir="$1"
  local relative_path="$2"

  if [ -e "${project_dir}/.module/${relative_path}" ]; then
    printf '%s\n' "${project_dir}/.module/${relative_path}"
  else
    printf '%s\n' "${project_dir}/.project/${relative_path}"
  fi
}
