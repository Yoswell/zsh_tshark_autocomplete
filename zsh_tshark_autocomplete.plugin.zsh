#!/bin/zsh

# TShark completion plugin for Oh My Zsh

# Load completion utilities
autoload -Uz compinit compdef

# Define plugin directory
local PLUGIN_DIR="${0:h}"

# Add completions directory to fpath
fpath=("$PLUGIN_DIR/Completions" $fpath)

# Initialize completion system
compinit

# Load tshark completion
if [[ -f "$PLUGIN_DIR/Completions/_tshark.zsh" ]]; then
  source "$PLUGIN_DIR/Completions/_tshark.zsh"
fi