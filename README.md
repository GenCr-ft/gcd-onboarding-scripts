# README: GenCr@t Studio Onboarding Script (`gft-onboarding.sh`)

## 1. Introduction

Welcome to GenCr@t Studio!

This script is your automated assistant for setting up a complete, standardized local development environment. It is designed to ensure that every technical member of the studio, regardless of their role, has the correct tools, configurations, and repository access from day one.

The script is **SSoT-Driven**, meaning it dynamically configures itself by reading approved standards directly from our `gcs-devops-standards` repository. This ensures your environment is always compliant with the latest studio policies.

## 2. Features

- **Cross-Platform:** Supports macOS (zsh), Linux (bash/zsh), and Windows (via WSL2 with Ubuntu LTS).
- **Role-Based Setup:** Interactively prompts you to select your studio role and installs the specific tools and repositories you need.
- **Idempotent:** Safe to re-run. The script checks the state of your system and only performs actions that are necessary.
- **Comprehensive:**
  - Installs and configures essential command-line tools (Git, GitHub CLI, etc.).
  - Sets up version managers for runtimes like Node.js and Python.
  - Configures your local Git identity.
  - Clones all necessary studio repositories into a structured workspace directory.
  - Installs a recommended set of VS Code extensions tailored to your role.
- **Robust & Transparent:** Provides clear output on actions being performed and creates a detailed log file at `~/gft_onboarding_YYYY-MM-DD.log` for troubleshooting.

## 3. Prerequisites

Before running the script, please ensure you have the following:

1. **Administrative Rights:** You will need `sudo` (for macOS/Linux) or Administrator (for Windows PowerShell) privileges to install system-level packages. The script will prompt for your password when needed.
2. **Internet Connection:** A stable internet connection is required to download tools and clone repositories.
3. **GitHub Account:** You must have an active GenCr@t GitHub account and have logged in at least once.

## 4. How to Use

Follow the instructions specific to your operating system.

### 4.1. For macOS & Linux Users

You will run the `gft-onboarding.sh` script directly in your terminal.

1. **Open your Terminal.**

2. **Download the script** using `curl`. This command downloads it into your current directory.

    ```bash
    curl -o gft-onboarding.sh <RAW_SCRIPT_URL_PROVIDED_BY_DEVOPS>
    ```

    *(Note: Replace `<RAW_SCRIPT_URL_PROVIDED_BY_DEVOPS>` with the actual URL to the script file.)*

3. **Make the script executable:**

    ```bash
    chmod +x gft-onboarding.sh
    ```

4. **Run the script:**

    ```bash
    ./gft-onboarding.sh
    ```

5. **Follow the on-screen prompts.** The script will guide you through role selection and ask for confirmation before making critical changes.

### 4.2. For Windows Users (via WSL2)

The process for Windows involves using a PowerShell script to prepare the Windows Subsystem for Linux (WSL2), which then runs the main Bash script.

1. **Open PowerShell as Administrator:**
    - Search for "PowerShell" in the Start Menu.
    - Right-click on "Windows PowerShell" and select "Run as administrator".

2. **Download the preparatory script** `onboarding-win.ps1`.

    ```powershell
    Invoke-WebRequest -Uri <RAW_WINDOWS_SCRIPT_URL> -OutFile .\onboarding-win.ps1
    ```

    *(Note: Replace `<RAW_WINDOWS_SCRIPT_URL>` with the actual URL.)*

3. **Run the script.** You may need to adjust your execution policy first.

    ```powershell
    # This command allows the script to run in the current session
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    # Run the preparatory script
    .\onboarding-win.ps1
    ```

4. **Follow the on-screen prompts.** The PowerShell script will:
    - Ensure WSL2 is enabled on your system (this may require a restart).
    - Guide you to install Ubuntu from the Microsoft Store if it's not present.
    - Launch the Ubuntu WSL2 terminal, which will **automatically download and run** the main `gft-onboarding.sh` script for you.

## 5. What to Expect During Execution

1. **Welcome & System Check:** The script will greet you and confirm your operating system.
2. **SSoT Download:** It will perform a temporary clone of the `gcs-devops-standards` repository to load its configuration.
3. **Role Selection:** You will be presented with a list of official studio roles. Please select the one that matches your position.
4. **Confirmation:** The script will display a summary of the actions it's about to take based on your role and ask for your final confirmation.
5. **Installation & Configuration:** The script will proceed to install tools, clone repositories, and configure your environment. You may be prompted for your password for `sudo` commands.
6. **Completion:** Upon successful completion, the script will provide final instructions and reminders.

## 6. Post-Installation Steps

After the script finishes, please perform the following steps:

1. **Restart Your Terminal:** Close and reopen all terminal/shell windows to ensure all changes to your environment (like new `PATH` entries) are loaded correctly.
2. **Restart VS Code:** If VS Code was open, restart it to load the newly installed extensions.
3. **Review the Log File:** If you encounter any issues, check the detailed log file located in your home directory (e.g., `~/gft_onboarding_2025-06-11.log`) for more information.

## 7. Troubleshooting

- **Permission Denied:** If you see "Permission Denied" when running `./gft-onboarding.sh`, ensure you have made it executable with `chmod +x gft-onboarding.sh`.
- **Package Manager Fails:** If a tool installation fails (e.g., via `apt` or `brew`), check your internet connection and ensure your package manager is up to date (`sudo apt update` or `brew update`).
- **GitHub Authentication Fails:** Ensure you have correctly set up your GitHub CLI authentication (`gh auth login`) when prompted by the script.

For any persistent issues, please contact the DevOps team on the `#devops-support` Slack channel.
  
  
