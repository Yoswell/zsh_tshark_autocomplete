#!/bin/zsh

# TShark completion plugin

# Load completion utilities
autoload -Uz compinit compdef

# Plugin paths
local PLUGIN_DIR="${0:h:h}"
local FIELDS_BASE_DIR="$PLUGIN_DIR/tshark/fields"
local HEADINGS_FILE="$PLUGIN_DIR/tshark/headings.txt"

# Display filter operators
local -a FILTER_OPERATORS=(
  'and' 'or' '&&' '||' 'not'
  'contains' 'matches' '=='
  '!=' '<' '>' '<=' '>='
)

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

# Parse the display filter to determine what to complete
_tshark_y_parse_filter() {
  local filter="$1"
  local -A result

  # Check if filter ends with an operator (after whitespace)
  if [[ "$filter" =~ '[[:space:]]+(and|or|&&|\\|\\|not)[[:space:]]*$' ]]; then
    result[state]='operator'
    return
  fi

  # Check if filter contains an operator and get the last part
  # This handles cases like "http and tcp" where we want to complete after "tcp"
  local -a parts

  # Split by operators (keep the operator as separate element)
  parts=(${=filter//' and '/' '})
  parts=(${parts//' or '/' '})
  parts=(${parts//' && '/' '})
  parts=(${parts//' || '/' '})
  parts=(${parts//' not '/' '})
  parts=(${parts//' contains '/' '})
  parts=(${parts//' matches '/' '})
  parts=(${parts//' == '/' '})
  parts=(${parts//' != '/' '})
  parts=(${parts//' < '/' '})
  parts=(${parts//' > '/' '})
  parts=(${parts//' <= '/' '})
  parts=(${parts//' >= '/' '})

  # Get the last non-empty part
  local last_part=""
  for ((i=${#parts[@]}; i>=1; i--)); do
    if [[ -n "${parts[i]}" ]]; then
      last_part="${parts[i]}"
      break
    fi
  done

  result[last_part]="$last_part"
}

# Completion for -Y (display filter)
_tshark_y() {
  local current="${words[CURRENT]}"

  # Strip quotes
  current="${current#\'}"
  current="${current%\'}"
  current="${current#\"}"
  current="${current%\"}"

  # Check if we're at the start or after an operator
  local prev_word="${words[CURRENT-1]}"

  # Check if current word ends with an operator (user is typing operator)
  local ends_with_op=0
  for op in "${FILTER_OPERATORS[@]}"; do
    if [[ "$current" == *"$op"* ]]; then
      # User might be typing an operator
      break
    fi
  done

  # Check if previous word is an operator
  local is_after_operator=0
  for op in "${FILTER_OPERATORS[@]}"; do
    if [[ "$prev_word" == "$op" ]]; then
      is_after_operator=1
      break
    fi
  done

  # Also check if the word before previous is an operator (for cases like "http and ")
  if [[ $is_after_operator -eq 0 && ${#words[@]} -gt 2 ]]; then
    local prev_prev_word="${words[CURRENT-2]}"
    for op in "${FILTER_OPERATORS[@]}"; do
      if [[ "$prev_prev_word" == "$op" ]]; then
        is_after_operator=1
        break
      fi
    done
  fi

  # If we're after an operator or at the start, suggest operators first
  if [[ -z "$current" && $is_after_operator -eq 0 ]]; then
    # At the beginning, suggest protocols
    _load_headings

    local -a matches
    for h in "${HEADINGS[@]}"; do
      [[ -z "$current" || "$h" == "$current"* ]] && matches+=("$h")
    done

    (( ${#matches[@]} )) && _values 'TShark protocols' "${matches[@]}"
    return
  fi

  # If we're after an operator, suggest protocols/fields
  if [[ $is_after_operator -eq 1 || -z "$current" ]]; then
    _load_headings

    local -a matches
    for h in "${HEADINGS[@]}"; do
      [[ -z "$current" || "$h" == "$current"* ]] && matches+=("$h")
    done

    (( ${#matches[@]} )) && _values 'TShark protocols' "${matches[@]}"
    return
  fi

  # User is typing an operator - suggest operators
  local -a op_matches
  for op in "${FILTER_OPERATORS[@]}"; do
    [[ "$op" == "$current"* ]] && op_matches+=("$op")
  done

  if (( ${#op_matches[@]} )); then
    _values 'Filter operator' "${op_matches[@]}"
    return
  fi

  # No dot → show headings (but only if no operator was typed)
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

  # Use compadd with _describe for better behavior
  if (( ${#matches[@]} )); then
    _describe -t tshark-field 'TShark field' matches
  fi
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

