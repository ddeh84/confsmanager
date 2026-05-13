#!/bin/sh

set -eu

INPUT_DIRECTORY="${1:-/var/lib/confsmanager/input}"
OUTPUT_DIRECTORY="${2:-/var/lib/confsmanager/output}"

TEMPLATE_CACHE_DIR="${OUTPUT_DIRECTORY}/.templates"


if [ ! -d "${INPUT_DIRECTORY}" ]; then
  printf "Error : Input directory '%s' does not exist or is not a directory.\n" "${INPUT_DIRECTORY}" >&2
  exit 1
fi

if [ ! -d "${OUTPUT_DIRECTORY}" ]; then
  printf "Error : Output directory '%s' does not exist or is not a directory.\n" "${OUTPUT_DIRECTORY}" >&2
  exit 1
fi

process_plain_files() {
  find "${INPUT_DIRECTORY}" -type f ! -name '*.sh' -print | while read -r file; do
    output_file="${OUTPUT_DIRECTORY}/$(basename "${file}")"

    # Check if output file has changed and update it
    if ! cmp -s "${file}" "${output_file}"; then
      cp -vf "${file}" "${output_file}"
    fi
  done
}

process_template_files() {
  find "${INPUT_DIRECTORY}" -type f -name '*.sh' -print | while read -r file; do
    [ ! -d "${TEMPLATE_CACHE_DIR}"  ] && mkdir -vp "${TEMPLATE_CACHE_DIR}"

    temp_file="$(mktemp)"

    cache_file="${TEMPLATE_CACHE_DIR}/$(basename "${file}")"
    output_file="${OUTPUT_DIRECTORY}/$(basename "${file}" .sh)"

    # Check if template file has changed
    if [ ! -f "${cache_file}" ] || ! cmp "${file}" "${cache_file}"; then
      # Execute template
      if /bin/sh "${file}" > "${temp_file}"; then
        ls -l "${temp_file}"

        # Check if output file has changed
        if ! cmp "${temp_file}" "${output_file}"; then
          # Update output file
          mv -vf "${temp_file}" "${output_file}"
        fi

        # Update template cache
        cp -vf "${file}" "${cache_file}"
      else
        rm -vf "${temp_file}"
        printf "Error : Failed to execute template file '%s'.\n" "${file}" >&2
      fi
    fi
  done
}

cleanup_output() {
  input_files="$(cd "${INPUT_DIRECTORY}" && find . -type f -printf '%P\n' | sort)"
  output_files="$(cd "${OUTPUT_DIRECTORY}" && find . -type f -printf '%P\n' | sort)"

  # Compare files list and remove old files
  comm -23 <(echo "${input_files}") <(echo "${output_files}") | while read -r file; do
    rm -vf "${OUTPUT_DIRECTORY}/${file}"
  done
}

process_plain_files
process_template_files
cleanup_outputead p
