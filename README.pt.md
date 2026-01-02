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

### Benefícios

* **Poupa tempo** ao evitar configurações manuais e resolução de problemas
* **Reduz a complexidade** com implementações claras e previsíveis
* **Resultados repetíveis** em diferentes sistemas e ambientes
* **Entrega de serviços** mais rápida, desde um sistema limpo até ao serviço em funcionamento
* **Configurações por defeito** mais seguras, com boas práticas integradas


## Instalação

Instale o ADR descarregando o script de arranque e colocando-o no PATH do sistema:

```bash
curl -fsSL https://raw.githubusercontent.com/skillmio/adr/main/adr.sh -o /tmp/adr && \
chmod +x /tmp/adr && \
sudo mv /tmp/adr /usr/local/bin/adr
```

Após a instalação, o comando `adr` ficará disponível em todo o sistema.

Pode verificar a instalação com:

```bash
adr -h
```
>
>
> [!NOTE]
> Os roles do ADR destinam-se a ser executados num **servidor recém-instalado**.
> Faça sempre um snapshot do sistema antes de implementar um role, para poder reverter e tentar novamente sem reinstalar o sistema operativo.

## Utilização

O ADR permite implementar serviços utilizando um único comando.

### Implementar um serviço

```bash
adr wordpress
```

Outros exemplos:

```bash
adr glpi
adr bookstack
```


O ADR faz automaticamente:

* Deteta o sistema operativo e a respetiva versão
* Descarrega a configuração correta do serviço
* Instala e configura o serviço
* Aplica definições sensatas por defeito


### Listar de serviços disponíveis

Para ver todos os roles disponíveis para o seu sistema:

```bash
adr -l
```
ou
```bash
adr --list
```

### Procurar um role (pesquisa flexível)

O ADR inclui **fpesquisa flexível (fuzzy search)**, pelo que não é necessário saber o nome exato do role.

```bash
adr --find word
adr -f stack
adr -f wp
```

A pesquisa flexível corresponde a entradas parciais ou abreviadas, tornando a descoberta de roles mais rápida e intuitiva.

### Atualização automática

O ADR verifica automaticamente se existem atualizações sempre que é executado.

Se estiver disponível uma nova versão, o ADR irá:

* Descarregar o script mais recente
* Substituir o binário local
* Continuar a execução utilizando a versão atualizada

Não são necessários passos manuais de atualização.

### Diagnostics

O ADR inclui diagnósticos integrados para ajudar na resolução de problemas.

```bash
adr -d
```
Este comando verifica:

* Instalação do ADR
* Ficheiros de configuração
* Ficheiros de idioma
* Conectividade de rede
* Disponibilidade da API de roles

Para corrigir automaticamente os problemas detetados:

```bash
adr -r
```
ou 
```bash
adr --repair
```
Este comando volta a descarregar o ADR e os ficheiros de idioma (é necessária ligação à Internet).

### Suporte de idiomas

O ADR suporta vários idiomas e memoriza a sua preferência.

Definir o idioma permanentemente:

```bash
adr -lg pt
```

Idiomas disponíveis:

* `en` — Inglês
* `pt` — Português
* `fr` — Francês


### Ajuda

Para mostrar a informação de utilização:

```bash
adr -h
```
ou
```bash
adr --help
```
>[!NOTE]
>O ADR foi concebido para**AlmaLinux e distribuições compatíveis com RHEL**
>
>São necessários privilégios de root para instalar e configurar serviços
>
>As configurações dos roles são selecionadas automaticamente com base na versão do sistema operativo
>
>O ADR destina-se a uma instalação de servidor recente
