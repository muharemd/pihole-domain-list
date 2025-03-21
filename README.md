# Pi-hole Domain List Automation Script

This repository contains a Bash script designed to automate the process of managing blocklists for Pi-hole, a network-wide ad blocker. The script dynamically downloads, merges, and processes domain blocklists, ensuring your Pi-hole setup remains up-to-date with the latest malicious domains.

## Features
- **Dynamic Working Directory**: Automatically sets the working directory based on the script's location.
- **Backup Support**: Creates a Teleporter backup archive of your Pi-hole configuration.
- **Blocklist Management**:
  - Downloads blocklists from reliable sources.
  - Merges multiple lists into one unified blocklist.
  - Removes duplicates and cleans up entries.
- **Domain Processing**: Fetches and validates domains from the blocklists, ensuring only relevant entries are included.
- **Error Logging**: Logs errors for troubleshooting and debugging.

## Prerequisites
Ensure the following tools are installed on your system:
- `curl`
- `wget`
- `dos2unix`
- `sed`
- `awk`

Additionally, Pi-hole must be installed and accessible on your system.

## Usage

### Make the Script Executable
Clone this repository and navigate to its directory:

```bash
git clone https://github.com/muharemd/pihole-domain-list.git
cd pihole-domain-list
```

Make the script executable:
```bash
chmod +x pihole_add_list_create.sh
```

### Run the Script
To display the help message:
```bash
./pihole_add_list_create.sh --help
```

To create a Pi-hole backup archive:
```bash
./pihole_add_list_create.sh backup
```

To update blocklists and flush the Pi-hole cache:
```bash
./pihole_add_list_create.sh
```

### Adding the Generated Blocklist to Pi-hole
After running the script, the consolidated blocklist will be saved at:
```
file:///home/$USER/pihole-domain-list/biglist
```

Follow these steps to add the generated `biglist` to your Pi-hole block lists:
1. Log in to your Pi-hole admin panel.
2. Navigate to **Group Management** > **Adlists**.
3. Add the following URL to the list:
   ```
   file:///home/$USER/pihole-domain-list/biglist
   ```
4. Click **Save** to apply the changes.
5. Run `pihole -g` from the command line to update Pi-hole with the new blocklist.

### Error Logs
Error messages are recorded in `error.log` located in the working directory:
```bash
cat error.log
```

## Contributions
Feel free to fork this repository, submit pull requests, or open issues if you have suggestions for improvements.

## License
This project is open-source and licensed under the [MIT License](LICENSE).
---

For further assistance or questions, please reach out via the [repository issues page](https://github.com/muharemd/pihole-domain-list/issues).
