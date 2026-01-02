📦 Available roles: 4

[Check Roles Status](roles_status.md)

<div align="center">
  <h1>Auto-Deploy Role (adr)</h1>
  <h3>
    A Linux automation tool that saves you time by deploying roles with one command
  </h3>

  <a href="https://github.com/skillmio/adr/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/skillmio/adr" alt="License">
  </a>

  <p>
    <code>adr --help</code> · <code>adr --list</code> · <code>adr --find</code> · <code>adr --diag</code> · <code>adr --repair</code>
  </p>

  <img
    src="https://github.com/skillmio/adr/blob/main/adr-image.png?raw=true"
    alt="ADR example"
    width="80%"
  />

  <p>
    screenshot
  </p>
</div>


## Intro

**ADR (Auto-Deploy Role)** is a Linux automation tool that helps you deploy services **quickly, consistently, and with minimal effort**.

Instead of manually installing packages, editing configuration files, and securing services step by step, ADR lets you deploy complete service roles using **a single command**. Each role takes care of installation, configuration, and sensible defaults so you can focus on using the service, not setting it up.

ADR is inspired by PowerShell’s `Install-WindowsFeature`, bringing the same **one-command, repeatable deployment experience** to Linux.

Whether you are managing servers, running a homelab, or automating deployments, ADR makes service deployment faster and more reliable.

### Features

* **One-command role deployment**
  Deploy services like WordPress, GLPI, or BookStack with a single command.

* **Modular roles**
  Each role is self-contained and handles installation, configuration, and basic security.

* **Repeatable and consistent**
  Get the same results every time, across different systems.

* **Linux-focused**
  Designed specifically for almaLinux servers and common deployment scenarios.

* **Automation-friendly**
  Easy to use interactively and easy to integrate into scripts or automation pipelines.

### Benefits

* **Save time** by avoiding manual setup and troubleshooting
* **Reduce complexity** with clear, predictable deployments
* **Repeatable results** across systems and environments
* **Faster service delivery** from fresh system to running service
* **Safer defaults** with built-in configuration and best practices


## Installation

Install ADR by downloading the launcher script and placing it in your system path:

```bash
curl -fsSL https://raw.githubusercontent.com/skillmio/adr/main/adr.sh -o /tmp/adr && \
chmod +x /tmp/adr && \
sudo mv /tmp/adr /usr/local/bin/adr
```

Once installed, the `adr` command will be available system-wide.

You can verify the installation with:

```bash
adr -h
```
>
>
> [!NOTE]
> ADR roles are intended to be executed on a **fresh server install**.
> Always take a system snapshot before deploying a role so you can roll back and retry without reinstalling the operating system from scratch.

## Usage

ADR allows you to deploy services using a single command.

### Deploy a role

```bash
adr wordpress
```

Other examples:

```bash
adr glpi
adr bookstack
```


ADR automatically:

* Detects your OS and version
* Downloads the correct role config
* Installs and configures the service
* Applies sensible defaults


### List available roles

To see all available roles for your system:

```bash
adr -l
```
or
```bash
adr --list
```

### Find a role (fuzzy search)

ADR includes **fuzzy role search**, so you don’t need to know the exact role name.

```bash
adr --find word
adr -f stack
adr -f wp
```
Fuzzy search matches partial and abbreviated input, making role discovery faster and more user-friendly.

### Self-Updating

ADR automatically checks for updates each time it runs.

If a newer version is available, ADR will:

* Download the latest script
* Replace the local binary
* Continue using the updated version automatically

No manual update steps are required.

### Diagnostics

ADR includes built-in diagnostics to help troubleshoot issues.

```bash
adr -d
```

This command checks:

* ADR installation
* Configuration files
* Language files
* Network connectivity
* Role API availability

To automatically fix detected issues:

```bash
adr -r
```
or 
```bash
adr --repair
```
This will re-download ADR and language files (internet access required).

### Language support

ADR supports multiple languages and remembers your preference.

Set the language permanently:

```bash
adr -lg pt
```

Available languages include:

* `en` — English
* `pt` — Portuguese
* `fr` — French


### Help

To display usage information:

```bash
adr -h
```
or
```bash
adr --help
```
>[!NOTE]
>ADR is designed for **AlmaLinux and RHEL-compatible distributions**
>
>Root privileges are required to install and configure services
>
>Roles config are selected automatically based on your OS version
>
>ADR is intended for a fresh server install
