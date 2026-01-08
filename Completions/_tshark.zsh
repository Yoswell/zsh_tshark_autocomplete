#!/bin/zsh

# TShark completion plugin

# Load completion utilities
autoload -Uz compinit compdef

# Plugin paths
local PLUGIN_DIR="${0:h:h}"
local FIELDS_BASE_DIR="$PLUGIN_DIR/tshark/fields"
local HEADINGS_FILE="$PLUGIN_DIR/tshark/headings.txt"

# Load headings
_load_headings() {
  if [[ -f "$HEADINGS_FILE" ]]; then
    HEADINGS=( ${(f)"$(< "$HEADINGS_FILE")"} )
  else
    HEADINGS=()
  fi
}

# Load fields for a heading
_load_fields_for_heading() {
  local heading="$1"
  local fields_file="$FIELDS_BASE_DIR/${heading}.txt"

  [[ -f "$fields_file" ]] && cat "$fields_file"
}

# Completion for -Y (display filter)
_tshark_y() {
  local current="${words[CURRENT]}"

  # Strip quotes
  current="${current#\'}"
  current="${current%\'}"
  current="${current#\"}"
  current="${current%\"}"

  # No dot → show headings
  if [[ "$current" != *.* ]]; then
    _load_headings

    local -a matches
    for h in "${HEADINGS[@]}"; do
      [[ -z "$current" || "$h" == "$current"* ]] && matches+=("$h")
    done

    (( ${#matches[@]} )) && _values 'TShark protocols' "${matches[@]}"
    return
  fi

  # Dot present → show fields
  local heading="${current%%.*}"
  local prefix="${current#*.}"

  local -a fields
  fields=( ${(f)"$(_load_fields_for_heading "$heading")"} )

  # Remove heading prefix from fields (http.xxx → xxx)
  fields=( "${fields[@]#$heading.}" )

  (( ${#fields[@]} == 0 )) && return

  local -a completions

  # Normalize prefix
  local prefix_clean="${prefix%.}"
  local -a prefix_levels
  [[ -n "$prefix_clean" ]] && prefix_levels=( ${(s:.:)prefix_clean} )
  local prefix_depth=${#prefix_levels[@]}

  for field in "${fields[@]}"; do
    [[ -z "$field" ]] && continue

    local -a field_levels
    field_levels=( ${(s:.:)field} )

    # Must match already-typed levels
    for ((i=1; i<=prefix_depth; i++)); do
      [[ "${field_levels[i]}" != "${prefix_levels[i]}" ]] && continue 2
    done

    # Suggest only next level
    if (( ${#field_levels[@]} > prefix_depth )); then
      local next="${field_levels[prefix_depth+1]}"

      if (( prefix_depth == 0 )); then
        completions+=("$heading.$next")
      else
        completions+=("$heading.${prefix_clean}.$next")
      fi
    fi
  done

  completions=( ${(u)completions} )

  (( ${#completions[@]} )) && _values 'TShark fields' "${completions[@]}"
}

# Completion for -e (extract field)
_tshark_e() {
  _load_headings

  local -a all_fields

  for heading in "${HEADINGS[@]}"; do
    local -a fields
    fields=( ${(f)"$(_load_fields_for_heading "$heading")"} )
    for field in "${fields[@]}"; do
      [[ -n "$field" ]] && all_fields+=("$field")
    done
  done

  local current="${words[CURRENT]}"
  current="${current#\'}"
  current="${current%\'}"
  current="${current#\"}"
  current="${current%\"}"

  local -a matches
  for f in "${all_fields[@]}"; do
    [[ -z "$current" || "$f" == "$current"* ]] && matches+=("$f")
  done

  (( ${#matches[@]} )) && _values 'All TShark fields' "${matches[@]}"
}

# Main tshark completion
_tshark() {
  _arguments \
    '-r[read packets from file]:file:_files' \
    '-Y[display filter]:filter:_tshark_y' \
    '-e[field to extract]:field:_tshark_e' \
    '-T[output format]:format:(fields ek json pdml text)' \
    '-w[write packets to file]:file:_files' \
    '-i[use interface]:interface' \
    '-f[capture filter]' \
    '-s[snaplen]' \
    '-p[disable promiscuous mode]' \
    '-v[print version]' \
    '-h[print help]' \
    '*:file:_files'
}

# Register completion
compdef _tshark tshark
