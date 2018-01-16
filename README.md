# Medic in Docker for Local Development

This document outlines how to develop Medic and Medic-Exchange packs locally using Docker

- [Prerequisites](#prerequisites)
- [Installation - How To](#install-medic-docker)
    - [Helpful Commands](#helpful-commands)
    - [Install medic_chatops](#install-medic_chatops)
- [Installation - Explained](#what-just-happened)
    - [Volumes](#volumes)
        - [medic-exchange](#medic-exchange)
        - [stackstorm-bin](#stackstorm-bin)
        - [stackstorm-env](#stackstorm-env)
        - [stackstorm-configs](#stackstorm-configs)
    - [Install Scripts](#install-scripts)
- [Installing packs from medic-exchange](#installing-packs-from-medic-exchange)
- [Installing CLI Tools](#installing-cli-tools)
- [Chatops](#chatops)
    - [Medic_Chatops](#installing-medic_chatops)
- [Pack Configuration](#pack-configuration)



## READ FIRST!!

- **Check the [CHANGELOG.rst](https://github.com/StackStorm/st2-docker/blob/master/CHANGELOG.rst)** file for any potential
  changes that may require restarting containers.
- Be sure to use the latest `docker-compose.yml`. Run `git pull` in your `st2-docker` workspace!
- Run `st2ctl reload --register-all` to reload all services.
- **For information on how the stackstorm docker image is versioned, see [VERSIONING.md](https://github.com/StackStorm/st2-docker/blob/master/VERSIONING.md)**
- If a specific image is required, it is always best to be explicit and specify the Image ID. For example:
  ```
  stackstorm/stackstorm:2.5.0@{7f33f32b1495}
  ```


## TL;DR

```
make env
docker-compose up -d
docker-compose exec stackstorm bash
```

Open `https://localhost` in your browser. StackStorm Username/Password can be found in: `cat conf/stackstorm.env`

Running on Kubernetes? See [runtime/kubernetes-1ppc](./runtime/kubernetes-1ppc)



## Prerequisites

- [Docker CE for Mac](https://store.docker.com/editions/community/docker-ce-desktop-mac)
- [git](https://git-scm.com/)
- [node/npm](https://nodejs.org/)

## Install medic-docker

```
npm install -g js-yaml
git clone git@github.pie.apple.com:mick-mcgrath2/medic-docker.git
cd medic-docker
make env
```

> Modify values in `conf/stackstorm.env` appropriately

> **Note** For more information, see install instructions here: [st2-docker repo](https://github.com/stackstorm/st2-docker).

### Helpful Commands

#### Start

To start the container, run:
```
docker-compose up
```

Once that's finished, head over to `https://127.0.0.1` and log in with the credentials specified in `conf/stackstorm.env`.

#### Stop

To stop the container, run:
```
docker-compose down
```

#### Accessing Containers

Get a bash shell in the `stackstorm` container:

With meeic-docker running (`docker-compose up`), open a new terminal and enter:
```
docker exec -it stackstorm /bin/bash
```

> **Note** You can access other containers (like mongo or rabbitmq) by changing `stackstorm` to another container name (i.e. `mongo`) specified in `docker-compose.yml`

### Install Medic_Chatops

It is a good idea to go ahead and install medic_chatops, too, because many of the packs in Medic Exchange use it.


## What just happened?

The above commands will install medic-docker, configure some volumes that are used with Medic, and set up some install scripts for when the Docker containers start.

### Volumes

Volumes are useful to allow modification of files from outside the docker container while it is running.

> **Note** You can see the relevant volumes in `docker-compose.yml`.

#### medic-exchange

> medic-docker directory: `medic-docker/medic-exchange`

> Docker Container Directory: `/opt/stackstorm/medic-exchange`

- This is where all [Medic Exchange](https://github.pie.apple.com/medic-exchange) packs should be installed.
- When you [start the docker container](#start), any medic-exchange pack repositories in this directory will be [installed automatically](#install-scripts).

#### stackstorm-bin

> medic-docker directory: `medic-docker/stackstorm-bin`

> Docker Container Directory: `/opt/stackstorm/bin`

- The `medic-docker/stackstorm-bin` directory is where all stackstorm executables will be located.
- If your team has an existing CLI tool, it should be installed into this directory.
- For more information, see [Installing CLI Tools](#installing-cli-tools)

#### stackstorm-configs

> medic-docker directory: `medic-docker/stackstorm-configs`

> Docker Container Directory: `/opt/stackstorm/configs`

- Stackstorm's baked-in configuration files live here
- **non-sensitive** pack configuration data that can be logged in execution results can simply be passed into actions via default parameters ([More Info](https://docs.stackstorm.com/actions.html#parameters-in-actions))
    - **Note** This feature is not available on sre-tools.apple.com as it requires Stackstorm 2.4+
- **sensitive** pack configuration data that should not be logged in execution history can be accessed via Python actions directly ([Example](https://github.com/StackStorm-Exchange/stackstorm-pagerduty/blob/master/actions/launch_incident.py#L9))
- See [pack configuration](#pack-configuration) for more information

#### stackstorm-env

> medic-docker directory: `medic-docker/stackstorm-env`

> Docker Container Directory: `/opt/stackstorm/env`

- Many CLI tools in [github.pie.apple.com](https://github.pie.apple.com/icloud-automation-sre) use .env files for configuration. (Example: [hipchat-message](https://github.pie.apple.com/icloud-automation-sre/hipchat-message))
- This is where .env files will live for system level CLI tool configurations. (Example: [medic_chatops pack](https://github.pie.apple.com/medic-exchange/medic_chatops#env))
- In some cases, .env files are preferable to pack configurations because they allow for non-python server code to utilize system-level pack configurations without a risk of those values propogating up into execution history.

#### stackstorm-ssh

> medic-docker directory: `medic-docker/stackstorm-ssh`

> Docker Container Directory: `/opt/stackstorm/.ssh`

**Experimental**

#### stackstorm-gitconfig

> medic-docker directory: `medic-docker/stackstorm-gitconfig`

> Docker Container Directory: `/opt/stackstorm/.gitconfig`

**Experimental**


### Install Scripts

Scripts in the `/runtime/st2.d` directory will be executed when the Docker container is started (after st2 has been installed).  They are executed alphabetically.

- `/runtime/st2.d/0-install-packs.sh`
    - Installs some useful packs from [StackStorm Exchange](https://exchange.stackstorm.org/) such as email and st2
- `/runtime/st2.d/install-medic-exchange.sh`
    - Installs the packs that exist in the `medic-docker/medic-exchange` directory
- `/runtime/st2.d/configure-stackstorm-node.sh`
    - Sets up a symlink for node inside of `/opt/stackstorm/bin/node`.  This is used by some CLI tools.



## Installing packs from medic-exchange

Clone [medic-exchange](https://github.pie.apple.com/medic-exchange) repositories into the `medic-docker/medic-exchange` volume directory set up previously
```
cd medic-exchange
git clone git@github.pie.apple.com:medic-exchange/test.git
```

This is where pack development should happen.

### Seeing changes to packs during development

When **changes are made to files in a pack** or when **new packs are installed into the medic-exchange directory**, you'll need to re install the pack to sync the changes to the stackstorm database

From within the docker container:
```
st2 pack install file:////opt/stackstorm/medic-exchange/your_awesome_pack
```
> **Note** When updating packs while the docker container is running, changes must be committed for the changes to take effect (i.e. `git add . && git commit -m "message"`)

For more information on developing packs for medic-exchange, head over to the [medic-exchange contribution docs](https://github.pie.apple.com/icloud-automation-sre/medic/blob/master/docs/guides/medic-exchange.md)

## Installing CLI tools

If your team has an existing CLI tool, it should be installed into this directory.

### Node based CLI tools

The pattern for installing a node package is
```
cd /path/to/medic-docker/stackstorm-bin
git clone git@github.pie.apple.com:icloud-automation-sre/some-node-tool.git
cd some-node-tool
npm install
```

> **Note** `npm install` installs the pack dependencies defined in `package.json`


## Chatops

Chatops allows for communication between a chat service (such as HipChat) and StackStorm via Hubot.

There is a difference between how we listen to a room and how we post to a room.

### Listening

To 'listen' to things said inside a chatops (hipchat) room, StackStorm uses hubot and aliases - where hubot can be thought of as a 'trigger', and aliases can be thought of as 'rules'.
In order for hubot to be able to communicate with hipchat, it must be configured in the `/opt/stackstorm/chatops/st2chatops.env` file.  This file sets up:
- The hipchat server chatops will communicate with
- The credentials necessary to log in
- The alias of the bot (@medic for example)
- The rooms that the bot is logged into
    - The bot will only be logged into rooms that are configured in this file

> **Note** For any change to this file to take effect, st2chatops must be restarted via `service st2chatops restart`.

> **Note** Any hipchat user can start a direct conversation with the bot and trigger aliases via the direct messages.

> **Note** There currently is only support for **ONE st2chatops configuration file per server**.  This means that if we want Medic to be able to listen to multiple instances of HipChat, each instance will require its own server to run st2chatops.

### Posting

To post to a room, we have created our own mechanism (`medic_chatops.hipchat_post_html`) to post messages because StackStorm’s out-of-the-box chatops doesn’t currently support HTML posting to HipChat.
What this means is that we are using the [medic-exhcnage/medic_chatops pack](https://github.pie.apple.com/medic-exchange/medic_chatops) (and **not** the [ootb chatops pack](https://github.com/StackStorm/st2/tree/master/contrib/chatops)) for any html messages.
This also means that we typically want to [disable](https://github.pie.apple.com/medic-exchange/carnival/blob/dev/aliases/request-status.yaml#L13) the [standard, documented responses of aliases](https://docs.stackstorm.com/chatops/aliases.html#result-options) and integrate our responses into our workflows instead. ([Example](https://github.pie.apple.com/medic-exchange/carnival/blob/dev/actions/workflows/run-request-status.yaml#L29))

### Installing Medic_Chatops

#### Install Hipchat Message CLI Tool

Install [hipchat-message](https://github.pie.apple.com/icloud-automation-sre/hipchat-message) into `medic-docker/stackstorm-bin`
```
cd /path/to/medic-docker/stackstorm-bin
git clone git@github.pie.apple.com:icloud-automation-sre/hipchat-message.git
cd hipchat-message
npm install
```

#### Set Up Hipchat Credentials

Create a file `/path/to/medic-docker/stackstorm-env/.env-medic-chatops` with the following contents
```
HIPCHAT_MESSAGE_TOKEN=yourtoken
```

> **Note** If you do not have a development bot, please create one or contact Medic support for assistance.

#### Testing Hipchat Message

To test that the hipchat-message cli works, you can execute the following command from [within the Docker container](#accessing-containers):
```
DOTENV_CONFIG_PATH=/opt/stackstorm/env/.env-medic-chatops /opt/stackstorm/bin/node /opt/stackstorm/bin/hipchat-message/hipchat.js --room "medic" --message "<span>Hello</span>"
```

> **Note** If you want to send a direct message, the `room` option should begin with `@` (ex:  `--room @mick`)

#### Get medic_chatops pack

- Clone the repo
```
cd /path/to/medic-docker/medic-exchange
git clone git@github.pie.apple.com:medic-exchange/medic_chatops.git
```

- Log into the StackStorm Docker container ([More Info](#accessing-containers))

- Install the pack
```
st2 pack install file:////opt/stackstorm/medic-exchange/medic_chatops
```

([More Info](#installing-packs-from-medic-exchange))



## Pack Configuration

Packs can take advantage of StackStorm configuration by including a `config.schema.yaml` file.

**Example**
```
---
  auth_key:
    description: "Auth Key"
    type: "string"
    secret: true
    required: true
```

To configure the pack, log into the stackstorm docker instance and run `st2 pack config my_awesome_pack`

**Example:**
```
root@8da7622210c4:/# st2 pack config my_awesome_pack
auth_key (secret): ********
---
Do you want to preview the config in an editor before saving? [y]: y
---
Do you want me to save it? [y]: y
+----------+----------------------------+
| Property | Value                      |
+----------+----------------------------+
| id       | 5a1de72a3a3fe400defe6461   |
| pack     | my_awesome_pack            |
| values   | {                          |
|          |     "auth_key": "********" |
|          | }                          |
+----------+----------------------------+
```

This will create a file in the `stackstorm-configs` (`/opt/stackstorm/config`) called `my_awesome_pack.yaml`

> **Note** Config properties with `secret:true` will be masked.

> **Note** Changes to pack configurations (files in `/opt/stackstorm/config`) require configurations to be sync'd with the database via `st2ctl reload --register-configs`

> **Note** For more information on pack configuration, see [StackStorm's docs on Pack Configuration](https://docs.stackstorm.com/reference/pack_configs.html)


### Set up some configuration files:

#### email
> **Note** Email pack not currently working for local development.  More investigation necessary.

Create a file in `stackstorm-configs/` called `email.yaml` with the following contents
```
imap_accounts:
  - name: "apple_main_imap"
    folder: "INBOX"
    port: 993
    server: "mail.apple.com" # change this if not usign apple mail
    username: "your_user"
    password: "your_password"
    ssl: True
    download_attachments: False
smtp_accounts:
  - name: "apple_main_smtp"
    server: "mail.apple.com"
    port: 587
    username: "your_user"
    password: "your_password"
    ssl: True
    download_attachments: False
attachment_datastore_ttl: 1800
max_attachment_size: 1024
```

> **Note** imap_accounts is required.





## Using the medic_github pack (**Experimental**)

### Configure git config

Create a `stackstorm-gitconfig` file in the repo with at least the following:
```
[user]
  name = Your Name
  email = email@email.com
```

Configure the `stackstorm-gitconfig` file as a volume for `/root/.gitconfig` in `docker-compose.yml`
```
    volumes:
      - ./stackstorm-gitconfig:/root/.gitconfig
```

### Create an ssh key for github.pie.apple.com

> **Note** The `medic_github` pack does not currently work with an ssh key that requires a password.

- [Generate a new ssh key](https://help.github.com/enterprise/2.10/user/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)
- Add the public key to [github.pie.apple.com/settings/keys](https://github.pie.apple.com/settings/keys)


### Configure `stackstorm-ssh`

Create a `stackstorm-ssh` directory in the repo:
```
mkdir `stackstorm-ssh`
```

Configure the `stackstorm-ssh` directory as a volume for `/root/.ssh` in `docker-compose.yml`
```
    volumes:
      - ./stackstorm-ssh:/root/.ssh
```

Copy your ssh key to `stackstorm-ssh/id_rsa`
```
cp /path/to/id_rsa_nopass path/to/stackstorm-ssh/id_rsa
```
> **Note:** This is currently how medic_github accesses medic-exchange.  This method is subject to change.


### Get the medic_github pack

Clone the `medic_github` pack into `medic-exchange` before running `docker-compose up`
```
git clone git@github.pie.apple.com:medic-exchange/medic_github.git
```

### Install Medic-Exchange Packs

You can now install packs from medic-exchange!
- Go to [Actions](https://127.0.0.1/#/actions)
- Open `MEDIC_GITHUB`
- Click `medic_exchange_pack_install`
- Enter a [medic-exchange](https://github.pie.apple.com/medic-exchange) repo name in the `pack` field
  - e.g. `medic_default`
- Click `Run`
- Once the execution has completed, refresh the [Actions page](https://127.0.0.1/#/actions) to see the pack