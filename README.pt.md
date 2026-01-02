<div align="right">

[![EN](https://img.shields.io/badge/lang-EN-blue)](README.md)
[![FR](https://img.shields.io/badge/lang-FR-blue)](README.fr.md)
[![PT](https://img.shields.io/badge/lang-PT-blue)](README.pt.md)

</div>

📦 [Ver serviços disponíveis:](roles_status.md) 4


<div align="center">
  <h1>Auto-Deploy Role (adr)</h1>
  <h3>
    Uma ferramenta de automação Linux que poupa tempo ao implementar serviços com um único comando
  </h3>

  <a href="https://github.com/skillmio/adr/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/skillmio/adr" alt="License">
  </a>

  <p>
    <code>adr --help</code> · <code>adr --list</code> · <code>adr --find</code> · <code>adr --diag</code> · <code>adr --repair</code>
  </p>

  <img
    src="https://github.com/skillmio/adr/blob/main/adr-image-pt.png?raw=true"
    alt="ADR example"
    width="80%"
  />

  <p>
    screenshot
  </p>
</div>


## Intro

**ADR (Auto-Deploy Role)** é uma ferramenta de automação Linux que ajuda a implementar serviços **de forma rápida, consistente e com o mínimo esforço**.

Em vez de instalar pacotes manualmente, editar ficheiros de configuração e proteger serviços passo a passo, o ADR permite implementar **roles completas com um único comando**.  
Cada role trata da instalação, configuração e definições seguras por defeito, permitindo-lhe focar-se na utilização do serviço.

O ADR é inspirado no `Install-WindowsFeature` do PowerShell, trazendo a mesma **experiência de implementação repetível com um único comando** para Linux.

Seja para servidores, homelabs ou automação de deploys, o ADR torna o processo mais rápido e fiável.

### Funcionalidades

* **Implementação com um único comando**
  Instale serviços como WordPress, GLPI ou BookStack facilmente.

* **Serviços modulares**
  Cada Serviço é autónomo e inclui instalação, configuração e segurança básica.

* **Resultados consistentes**
  O mesmo resultado em todos os sistemas.

* **Focado em Linux**
  Desenvolvido para servidores AlmaLinux.

* **Pronto para automação**
  Ideal para uso manual ou integração em scripts.

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
