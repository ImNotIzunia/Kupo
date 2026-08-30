# Kupo

[![CI](https://github.com/ImNotIzunia/Kupo/actions/workflows/ci.yml/badge.svg)](https://github.com/ImNotIzunia/Kupo/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENCE)
[![Bash](https://img.shields.io/badge/Bash-4.4%2B-4EAA25.svg)](https://www.gnu.org/software/bash/)

Kupo is a Bash backup utility for Linux that compress and copy designated folders to an external drive.

## Requirements

- Linux distribution with Bash support
- Bash 4.4 or later
- An external drive mounted and accessible
- Standard Unix tools such as `tar`, `gzip`, and `find`

## Installation

```bash
git clone https://github.com/your-user/Kupo.git
cd Kupo
chmod +x kupo.sh
```

No additional setup is required to run Kupo. If you plan to contribute or run automated checks, install the development dependencies listed in [Development](#-development).

## Usage

Run the launcher:

```bash
./kupo.sh
```

Or run the main script directly with Bash:

```bash
bash ./kupo.sh
```

You'll be greeted with the main menu:

```
1. Start Backup
2. Configuration
3. Languages
4. Exit
```

### First run

On first launch, Kupo creates a default configuration file at `config/config.json`. Head to the **Configuration** menu to:

- Set your backup drive (pick from a list of detected external drives)
- Set the backup folder name
- Add or remove source folders to back up

Once configured, select **Start Backup** from the main menu to compress and copy your sources to the backup destination.

### Languages

You can change the language of the app by going to the **Languages** menu. Available languages:

- French
- English

## Development

### Running tests

Kupo uses [Bats](https://bats-core.readthedocs.io/) for shell testing.

There is a script for running all the tests, make sure you have bats installed.

You can run the test file by the following :

```bash
bats ./tests/run
```

### Linting

Kupo uses [ShellCheck](https://www.shellcheck.net/) to validate script quality.

```bash
sudo apt install shellcheck
shellcheck ./kupo.sh
```

Both steps can be integrated into CI to run automatically on every push and pull request to `main` or `master`.

## Contribution

This is a personal project maintained by a single contributor.

All issues and pull requests are welcome. Please keep security and stability in mind when contributing.

You can also support the project by offering me a coffee !

<div align="center">

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/imnotizunia)

</div>

## License

MIT License.
