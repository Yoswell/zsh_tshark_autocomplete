### TShark Advanced Zsh Autocomplete – Hierarchical Display Filter Completion

Specialized command-line productivity tool that brings Wireshark-level field awareness to TShark display filters through advanced Zsh autocompletion.

* TShark display filter automation
* Hierarchical protocol and field resolution

[![ZSH](https://img.shields.io/badge/ZSH-black)]()
[![TSHARK](https://img.shields.io/badge/TSHARK-black)]()
[![AUTOCOMPLETE](https://img.shields.io/badge/AUTOCOMPLETE-black)]()
[![NETWORK](https://img.shields.io/badge/NETWORK-black)]()
[![v1.0](https://img.shields.io/badge/1.0-black)]()

-----

### What is TShark Advanced Zsh Autocomplete?

TShark Advanced Zsh Autocomplete is a specialized Zsh plugin designed to dramatically improve the usability of TShark by providing deep, protocol-aware, and hierarchical autocompletion for display filters (`-Y`) and extracted fields (`-e`).

Unlike traditional shell completions that only suggest flat protocol names or static options, this tool understands the internal structure of TShark fields and mirrors the same logical hierarchy used internally by Wireshark. This allows users to progressively explore protocols and their fields directly from the terminal, without memorizing field names or constantly switching to Wireshark’s GUI.

The goal of this project is to make complex packet filtering faster, safer, and more intuitive for analysts, CTF players, incident responders, and anyone who relies heavily on TShark in day-to-day workflows.

* **Hierarchical Field Autocomplete**: Progressively completes fields level by level (`http.request.uri.path`)
* **Protocol-Aware Suggestions**: Only valid protocol headings and fields are suggested
* **Deep Nesting Support**: Works with arbitrarily deep field trees without duplication
* **Display Filter Support**: Full autocomplete for the `-Y` display filter option
* **Field Extraction Support**: Autocomplete for `-e` extracted field definitions
* **Oh My Zsh Compatible**: Uses native Zsh completion mechanisms
* **Offline and Fast**: No runtime calls to tshark or Wireshark binaries

-----

### Quick Start

#### Prerequisites

* **Zsh**: Required shell environment
* **TShark / Wireshark**: Needed for packet analysis and field definitions
* **Oh My Zsh**: Recommended for plugin management
* **Python 3**: Required only if regenerating field databases

#### Installation & Setup

```bash
# Navigate to Oh My Zsh custom plugins directory
cd ~/.oh-my-zsh/custom/plugins

# Clone the repository
git clone https://github.com/Yoswell/zsh_tshark_autocomplete.git
```

Add the plugin to your plugin list:

```bash
plugins=(
	zsh_tshark_autocomplete
)

if [ -f  ~/.oh-my-zsh/custom/plugins/zsh_tshark_autocomplete/zsh_tshark_autocomplete.plugin.zsh ]; then
  source ~/.oh-my-zsh/custom/plugins/zsh_tshark_autocomplete/zsh_tshark_autocomplete.plugin.zsh
  bindkey $key[Up] up-line-or-history
  bindkey $key[Down] down-line-or-history
fi

source $ZSH/oh-my-zsh.sh
```

Reload your shell:

```bash
source ~/.zshrc
```

> [!TIP]
> **First-Time Setup**: After installation, restart your terminal to ensure Zsh reloads the completion system correctly.

-----

#### Field Database Generator

The project includes a utility script to generate and maintain the field database:

```bash
python extract_fields.py
```

* Extracts all available TShark fields
* Groups fields by protocol heading
* Normalizes and deduplicates field paths
* Preserves hierarchical structure
* Updates `headings.txt` and `fields/*.txt`

-----

### How It Works

The completion engine always suggests **only the next valid level**, ensuring clean and precise completions without overwhelming the user with irrelevant fields.

#### Example Usage

```bash
# Press [TAB] after typing 'http.'
VIsh0k@VIsh0k:~/Desktop$ tshark -r capture.pcap -T fields -Y 'http. [TAB]'
http.accept                    http.content_range             http.path_sub_segment
http.accept_encoding           http.content_type              http.prev_request_in
http.accept_language           http.cookie                    http.prev_response_in
http.authbasic                 http.cookie_pair               http.proxy_authenticate
http.authcitrix                http.date                      http.proxy_authorization
http.authorization             http.decompression_disabled    http.proxy_connect_host
http.bad_header_name           http.decompression_failed      http.proxy_connect_port
http.body                      http.excess_data               http.range
# ...(omited content)
```

-----

### Integration with Packet Analysis Workflows

This plugin integrates seamlessly into existing TShark-based workflows:

* **Incident Response**: Rapidly explore packet fields during investigations
* **CTF Competitions**: Accelerate filter writing under time pressure
* **Network Debugging**: Discover protocol internals interactively
* **Detection Engineering**: Validate and refine display filters quickly

The tool is especially useful when dealing with complex protocols where field names are difficult to memorize or inconsistently documented.

> [!WARNING]
> **Accuracy Reminder**: Autocomplete assists with discovery, but it does not validate filter logic or guarantee semantic correctness of display filters.

-----

### Advanced Usage

#### Display Filter (`-Y`) Completion

```bash
# Press [TAB] after typing 'http.request'
-Y 'http.request. [TAB]'

# You will see the following completions
http.request.host              http.request.method              http.request.uri.path
# ...(omited content)
```

#### Extracted Field (`-e`) Completion

```bash
# Press [TAB] after typing 'http.response.'
-e http.response. [TAB]

# You will see the following completions
http.response.code             http.response.content_type       http.response.headers
# ...(omited content)
```

Both options share the same hierarchical resolution logic and field database.

-----

### Author & License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.