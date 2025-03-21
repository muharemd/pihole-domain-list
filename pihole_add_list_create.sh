#!/bin/bash

set -e
set -o pipefail

WORKDIR="$(dirname "$(realpath "$0")")"
sudo chmod -R u+w "$WORKDIR"
PIHOLE_CMD="/usr/local/bin/pihole"

function help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --help       Display this help message"
    echo "Backup:
	  Create a Teleporter backup archive of pihole in the
	  current directory and print its name"
    echo "Updating the lists and flushing the cache without restarting the DNS server"
    exit 
}

if [[ "$1" == "-h" || "$1" == "--help" ]]
	then help
fi

if [[ "$1" == "backup" ]]
  then
  echo "Backing up pihole" 
  sudo /usr/bin/pihole-FTL --teleporter
  exit
fi

# Ensure error.log exists and is writable
touch "$WORKDIR/error.log"
chmod 666 "$WORKDIR/error.log"

# Function to handle cleanup
function cleanup() {
    echo "Cleaning up..."
    purge_files
    echo "Cleanup complete."
}

# Trap signals and call cleanup
trap cleanup SIGINT SIGTERM

function purge_files() {
    echo "Purging old files..."
    : > "$WORKDIR/.test"
    : > "$WORKDIR/list2"
    : > "$WORKDIR/list3"
    : > "$WORKDIR/biglist"
    : > "$WORKDIR/updateGravity.log"
    rm -f "$WORKDIR/index.html"
    rm -f "$WORKDIR/firebog.html"
}

function download_block_lists() {
    echo "Downloading block lists..."
    echo -e "Merge current site_list with new one downloaded from \"https://firebog.net/\""
    wget -q https://v.firebog.net -O firebog.html
    if [ -f firebog.html ]; then
        cat firebog.html | sed 's|</b>|-|g' | sed 's|<[^>]*>||g' | sed 's/:h/\nh/g' | grep -Iv "^$" | grep -I http > $WORKDIR/list2
    else
        echo "firebog.html file not found."
        exit 1
    fi
    curl -s https://v.firebog.net/hosts/lists.php?type=all | grep -Iv "^$" > "$WORKDIR/list3"
    curl -s https://o0.pages.dev/-data/lists/assets.txt | grep -Iv Cheers | grep -Iv "^$" >> "$WORKDIR/list3"

    for url in $(curl -s https://v.firebog.net/hosts/ | grep -Eo 'href="[^"]+\.txt"' | cut -d'"' -f2); do
        echo "https://v.firebog.net/hosts/$url" >> "$WORKDIR/list3"
    done
}

function merge_and_clean_lists() {
    echo "Merging and cleaning block lists..."
    sort -u "$WORKDIR/list2" "$WORKDIR/list3" "$WORKDIR/master_lists" | awk 'NF' > "$WORKDIR/sites_list"
    echo "Total sites listed: $(wc -l < "$WORKDIR/sites_list")"
}

function fetch_and_process_domains() {
    echo "Fetching and processing domains..."
    cat "$WORKDIR/sites_list" | tr '\n' '\0' | xargs -0 -P 10 -I '{}' bash -c '
        url="{}"
	WORKDIR="$(dirname "$(realpath "$0")")"
        content=$(curl -s "$url" | dos2unix -f | tr -d "\0")
        echo "$content" | sed -E '\''s/[^[:print:]]//g; s/0\.0\.0\.0//g; s/[^a-zA-Z0-9.-]//g'\'' | \
        sed -E '\''s:/.*::; s/#.*//; s/[^a-zA-Z0-9.-]//g'\'' | grep -avE '\''^#|^$'\'' | sort | uniq >> "$WORKDIR/biglist"
    '
}

function update_pihole() {
    echo "Updating Pi-hole database..."
    sudo $PIHOLE_CMD -g > "$WORKDIR/updateGravity.log" 2>&1
    echo "Pi-hole update complete."
}

function function_pihole_update() {
    echo "Starting Pi-hole update script..."
    cd "$WORKDIR" || exit 1

    purge_files
    download_block_lists
    merge_and_clean_lists
    fetch_and_process_domains
    update_pihole
}

function_pihole_update
