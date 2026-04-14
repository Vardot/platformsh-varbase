# Varbase Project Template for Upsun

This project provides a starter kit for Varbase 11.0.x projects hosted on [Upsun](https://upsun.com). It
is very closely based on the [Varbase Composer project](https://github.com/Vardot/varbase-project).

This template builds Varbase ~11.0.0 using the Varbase Composer project template. It also includes configuration to use Redis for caching, although that must be enabled post-install in `.upsun/config.yaml`.

Drupal is a flexible and extensible PHP-based CMS framework.

## Quick start

```bash
git clone https://github.com/Vardot/upsun-varbase11x00 myproject
cd myproject
upsun project:create
upsun push
```

The default app is configured under `.upsun/` so no extra flags are needed.

## Services

- PHP 8.4
- MariaDB 10.11
- Redis 6
- Drush included
- Automatic TLS certificates
- Composer-based build

## Deploying to Upsun

1. Create a free trial:

   [Register for a free trial with Upsun](https://auth.upsun.com/register). When you have completed signup, select the **Create from scratch** project option. Give your project a name, and select a region where you would like it to be deployed. For the *Production environment* option, make sure to match it to this repository's settings, or to what you have updated the default branch to locally.

2. Install the Upsun CLI

   #### Linux/OSX

   ```bash
   curl -fsS https://upsun.com/cli/installer | php
   ```

   #### Windows

   ```bash
   curl -f https://upsun.com/cli/installer -o cli-installer.php
   php cli-installer.php
   ```

   You can verify the installation by logging in (`upsun login`) and listing your projects (`upsun project:list`).

3. Set the project remote

   Find your `PROJECT_ID` by running the command `upsun project:list`

   ```bash
   +---------------+------------------------------------+------------------+---------------------------------+
   | ID            | Title                              | Region           | Organization                    |
   +---------------+------------------------------------+------------------+---------------------------------+
   | PROJECT_ID    | Your Project Name                  | xx-5.upsun.com   | your-username                   |
   +---------------+------------------------------------+------------------+---------------------------------+
   ```

   Then from within your local copy, run the command `upsun project:set-remote PROJECT_ID`.

4. Push

   ```bash
   upsun push
   ```

   or

   ```bash
   git push upsun DEFAULT_BRANCH
   ```

<details>
<summary>Integrate with a GitHub repo and deploy pull requests</summary>

Consult the [GitHub integration documentation](https://docs.upsun.com/integrations/source/github.html) to finish connecting your repository to a project on Upsun. You will need to create an access token on GitHub to do so.

</details>

<details>
<summary>Integrate with a GitLab repo and deploy merge requests</summary>

Consult the [GitLab integration documentation](https://docs.upsun.com/integrations/source/gitlab.html) to finish connecting a repository to a project on Upsun. You will need to create an access token on GitLab to do so.

</details>

<details>
<summary>Integrate with a Bitbucket repo and deploy pull requests</summary>

Consult the [Bitbucket integration documentation](https://docs.upsun.com/integrations/source/bitbucket.html) to finish connecting a repository to a project on Upsun. You will need to create an access token on Bitbucket to do so.

</details>

### Post-install

Run through the Drupal installer as normal. You will not be asked for database credentials as those are already provided.

### Local development

This section provides instructions for running the template locally, connected to a live database instance on an active Upsun environment.

In all cases for developing with Upsun, it's important to develop on an isolated environment - do not connect to data on your production environment when developing locally.
Each of the options below assumes that you have already deployed this template to Upsun, as well as the following starting commands:

```bash
$ upsun get PROJECT_ID
$ cd project-name
$ upsun environment:branch updates
```

<details>
<summary>Drupal: using ddev</summary><br />

ddev makes it simple to develop Drupal locally. In general, the steps are as follows:

1. [Install ddev](https://ddev.readthedocs.io/en/stable/#installation).
1. [Retrieve an API token](https://docs.upsun.com/administration/cli/api-tokens.html) for your organization via the management console.
1. Update your ddev global configuration file to use the token you've just retrieved:
    ```yaml
    web_environment:
    - UPSUN_CLI_TOKEN=abcdeyourtoken
    ```
1. Run `ddev restart`.
1. Get your project ID with `upsun project:info`. If you have not already connected your local repo with the project, you can run `upsun project:list` to locate the project ID, and `upsun project:set-remote PROJECT_ID` to configure Upsun locally.
1. Get the current environment's data with `ddev pull upsun`.
1. When you have finished with your work, run `ddev stop` and `ddev poweroff`.

</details>
<details>
<summary>Drupal: using Lando</summary><br />

Lando supports PHP applications configured to run on Upsun.

1. [Install Lando](https://docs.lando.dev/getting-started/installation.html).
1. Make sure Docker is already running - Lando will attempt to start Docker for you, but it's best to have it running in the background before beginning.
1. Start your apps and services with the command `lando start`.
1. To get up-to-date data from your Upsun environment, run the command `lando pull`.
1. If at any time you have updated your Upsun configuration files, run the command `lando rebuild`.
1. When you have finished with your work, run `lando stop` and `lando poweroff`.

</details>

> **Note:**
>
> For many of the steps above, you may need to include the CLI flags `-p PROJECT_ID` and `-e ENVIRONMENT_ID` if you are not in the project directory or if the environment is associated with an existing pull request.

## Configuration files

|  File | Purpose    |
|:-----------|:--------|
| [`config/sync/.gitkeep`](config/sync/.gitkeep) | Drupal configuration sync directory |
| [`web/sites/default/settings.php`](web/sites/default/settings.php) | Drupal settings, imports `settings.platformsh.php` for Upsun integration |
| [`web/sites/default/settings.platformsh.php`](web/sites/default/settings.platformsh.php) | Upsun-specific configuration: database connection to MariaDB and Redis caching |
| [`.environment`](.environment) | Environment variables sourced before start, deploy, post_deploy hooks, and SSH sessions |
| [`.upsun/config.yaml`](.upsun/config.yaml) | **Primary Upsun configuration** — defines applications, services, routes, and the build/deploy process |
| [`drush/platformsh_generate_drush_yml.php`](drush/platformsh_generate_drush_yml.php) | Generates Drush YAML configuration on every deployment |
| [`php.ini`](php.ini) | PHP settings tuned for production, based on [Blackfire.io](https://blackfire.io) best practices |
| [`.blackfire.yml`](.blackfire.yml) | Starter [Blackfire.io](https://blackfire.io) configuration |
| [`.lando.upstream.yml`](.lando.upstream.yml) | [Lando](https://docs.lando.dev/) local development configuration |
| [`.ddev/config.yaml`](.ddev/config.yaml) | [ddev](https://ddev.readthedocs.io/) local development configuration |

## Migrating your data

If you are moving an existing site to Upsun, then in addition to code you also need to migrate your data.

<details>
<summary>Importing the database</summary><br/>

Obtain a database dump from your current site and save it as `database.sql`. Then import the database into your Upsun site using the CLI:

```bash
upsun sql -e main < database.sql
```

</details>
<details>
<summary>Importing files</summary><br/>

Download your files from your current hosting environment first.

The `upsun mount:upload` command provides a straightforward way to upload an entire directory to a `mount` defined in your Upsun configuration.

```bash
$ upsun mount:upload -e main --mount web/sites/default/files --source ./web/sites/default/files
$ upsun mount:upload -e main --mount private --source ./private
```

Note that `rsync` is picky about its trailing slashes, so be sure to include those.

</details>

## Learn

### Troubleshooting

<details>
<summary><strong>Accessing logs</strong></summary><br/>

After the environment has finished its deployment, investigate issues using:

```bash
upsun ssh
```

If you are running the command outside of a local copy of the project, you will need to include the `-p` (project) and/or `-e` (environment) flags. Once connected to the container, logs are available within `/var/log/`.

</details>

<details>
<summary><strong>Rebuilding cache</strong></summary><br/>

If you run into a database error after installing Drupal on production initially, SSH in (`upsun ssh`) and rebuild the cache:

```bash
drush cache-rebuild
```

</details>

### Blackfire.io

This template includes a starter [`.blackfire.yml`](.blackfire.yml) file for [Application Performance Monitoring](https://blackfire.io/docs/monitoring-cookbooks/index), [Profiling](https://blackfire.io/docs/profiling-cookbooks/index), [Builds](https://blackfire.io/docs/builds-cookbooks/index) and [Performance Testing](https://blackfire.io/docs/testing-cookbooks/index). Upsun comes with Blackfire pre-installed on application containers.

### Resources

- [Drupal](https://www.drupal.org/)
- [Varbase](https://www.drupal.org/project/varbase)
- [Vardot](https://www.drupal.org/vardot)
- [Upsun documentation](https://docs.upsun.com)
- [Drupal on Upsun](https://docs.upsun.com/get-started/stacks/drupal.html)
- [PHP on Upsun](https://docs.upsun.com/languages/php.html)

### About Upsun

Upsun is a unified, secure, enterprise-grade platform for building, running and scaling web applications — every branch becomes a development environment, infrastructure is described in simple YAML, and production data can be cloned into isolated preview environments in seconds.

## Contribute

See something that's wrong with this template that needs to be fixed? Something in the documentation unclear or missing? Let us know!

- [Report a bug](https://github.com/Vardot/upsun-varbase11x00/issues/new)
- [Open a pull request](https://github.com/Vardot/upsun-varbase11x00/pulls)
