# Django Platform

[![License](https://img.shields.io/github/license/ualaska-it/django_platform.svg)](https://github.com/ualaska-it/django_platform)
[![GitHub Tag](https://img.shields.io/github/tag/ualaska-it/django_platform.svg)](https://github.com/ualaska-it/django_platform)

__Maintainer: OIT Systems Engineering__ (<ua-oit-se@alaska.edu>)

## Purpose

This is a baseline cookbook that installs/configures a platform consisting of Python 3 and Django 2.
It then deploys a Django application from a git repository.

Django is run on an Apache instance that is configured using [http_platform](https://github.com/ualaska-it/http_platform).

## Requirements

### Chef

This cookbook requires Chef 14+

### Platforms

Supported Platform Families:

* Debian
  * Ubuntu, Mint
* Red Hat Enterprise Linux
  * Amazon, CentOS, Oracle

Platforms validated via Test Kitchen:

* Ubuntu
* CentOS

### Dependencies

This cookbook does not constrain its dependencies because it is intended as a utility library.
It should ultimately be used within a wrapper cookbook.

## Resources

This cookbook provides no custom resources.

## Recipes

### django_platform::default

This recipe configures the host platform and deploys a Django application.
The [http_platform](https://github.com/ualaska-it/http_platform) recipe is run as part of this.

## Attributes

### Default

Some attributes are overridden from the [http_platform](https://github.com/ualaska-it/http_platform) cookbook.

* `node['http_platform']['apache']['extra_mods_to_install']`.
Defaults to `node['http_platform']['apache']['extra_mods_to_install'].merge('alias' => '')`.
The list of Apache mods to install.
Clients should merge this attribute rather than overwrite because mod alias is required for Django to function.
In addition, mod_wsgi is installed by Pip.

* `node['http_platform']['apache']['paths_to_additional_configs']`.
Defaults to `node['http_platform']['apache']['paths_to_additional_configs'].merge('conf.d/django-host.conf' => '')`.
The list of config files to enable on the virtual host,
As with the default from the [http_platform](https://github.com/ualaska-it/http_platform), this should be merged instead of overridden unless a custom server configuration is desired.

* `node['http_platform']['www']['header_policy']['referrer']`.
Defaults to `'"strict-origin"'`.
The referrer policy.
Django forms use a CSRF token to mitigate cross-site forgery attacks.
This requires the referrer to be included in the header.
This setting provides the referrer only for HTTPS traffic to mitigate other vulnerability; HTTP is redirected to HTTPS by the default [http_platform](https://github.com/ualaska-it/http_platform) configuration.

### App

__Git checkout__

This cookbook assumes the django application is contained in a git repo.
Due to limitations of the built-in [git resource](https://docs.chef.io/resource_git.html), only SSH access is supported.
Submodules will be checked out recursively, and these can use HTTP.

* `node['django_platform']['app_repo']['git_host']`.
Defaults to `'github.com'`.
The url of the git server from which to fetch the Django application.

* `node['django_platform']['app_repo']['git_user']`.
Defaults to `nil`.
The user/organization on the git server; must be set or an exception is raised.

* `node['django_platform']['app_repo']['git_repo']`.
Defaults to `nil`.
The name of the repo within the git organization; must be set or an exception is raised.

* `node['django_platform']['app_repo']['git_revision']`.
Defaults to `'master'`.
The branch, tag, or commit to check out.
This is often changed during development and testing, e.g. 'staging', 'deploy'.

* `node['django_platform']['app_repo']['git_submodule_hosts']`.
Defaults to `['github.com']`.
A list of hosts from which submodules are cloned.
Used to build the known hosts file so the first attempt to clone the repo succeeds.

* `node['django_platform']['app_repo']['environment']`.
Defaults to `{}`.
A hash of environment variables that is passed to the [git resource](https://docs.chef.io/resource_git.html).

__Server hooks__

Deployment of the app requires several hooks into the application repo so that server paths can be set.

* `node['django_platform']['app_repo']['rel_path_to_pip_requirements']`.
Defaults to `nil`.
The relative path to the requirements document, from repo root.
If non-nil, pip will be used to install the requirements.

* `node['django_platform']['app_repo']['rel_path_to_manage_directory']`.
Defaults to `nil`.
The relative path to the directory that contains manage.py, from repo root.
Must be set or an exception is raised.

* `node['django_platform']['app_repo']['rel_path_to_site_directory']`.
Defaults to `nil`.
The relative path to the directory that contains settings.py and wsgi.py, from repo root.
Must be set or an exception is raised.

* `node['django_platform']['app_repo']['rel_path_to_static_directory']`.
Defaults to `nil`.
The relative path to the directory from which static files are to be served, from repo root.
If `STATIC_ROOT` is set in settings.py, `manage.py collectstatic` will be run every time the git repo changes.
Must be set or an exception is raised.

* `node['django_platform']['app_repo']['rel_path_to_sqlite_db']`.
Defaults to `nil`.
The relative path to the sqlite database, from repo root.
If non-nil, permissions of this file will be managed, after all management commands and scripts have run.
Management of Postgres has not yet been implemented.

__Deployment hooks__

The platform supplies several hooks so clients can run custom code during deployment.
The checkout workflow is as follows.

* Run pre-checkout recipes, see `node['django_platform']['app_repo']['additional_recipes_before_checkout']`
* Synchronize the git repo
* Run pre-install recipes, see `node['django_platform']['app_repo']['additional_recipes_before_checkout']`
* If the git repo changed
  * Install all entries in `requirements.txt`, if the cookbook is configured to do so
* Run pre-migrate recipes, `node['django_platform']['app_repo']['additional_recipes_before_install']`
* If the git repo changed
  * Migrate the database `manage.py migrate`
  * Collect static files `manage.py collectstatic`, if the Django app is configured for it
  * Run a list of custom management commands, see `node['django_platform']['app_repo']['additional_management_commands']`
  * Run a list of custom bash scripts, with the python environment for Django activated, `node['django_platform']['app_repo']['additional_shell_scripts']`

Pre-checkout, pre-install, and pre-migrate recipes are run _unconditionally_.
A flag is provided to indicate if the repo updated.

* `node['django_platform']['app_repo']['git_repo_updated']`.
Defaults to `false`.
Set to true within a recipe if the git repo updated.
Typically used within only_if blocks to trigger deployment code on update.

For the apache/wsgi server to gain access to any file system resources, all directories and files must have the appropriate permissions.
Helpers specify the user (`django_user`) and group (`django_group`) used by the platform for file resources that are to be accessed by the server.

* `node['django_platform']['app_repo']['additional_recipes_before_checkout']`.
Defaults to `[]`.
A list of recipes to include after the `django_user` is created, but before cloning the git repo.

* `node['django_platform']['app_repo']['additional_recipes_before_install']`.
Defaults to `[]`.
A list of recipes to include after cloning the git repo, but before installing requirements.

* `node['django_platform']['app_repo']['additional_recipes_before_migration']`.
Defaults to `[]`.
A list of recipes to include after installing requirements, but before migrating the database.

* `node['django_platform']['app_repo']['additional_management_commands']`.
Defaults to `[]`.
An array of management commands to call after the repo updates.
Commands are executed in order, after migration and (possibly) collectstatic.
This attribute is included to support limited cases where an application can be deployed using only node attributes.

* `node['django_platform']['app_repo']['additional_shell_scripts']`.
Defaults to `[]`.
An array of relative paths to bash scripts, from repo root, to execute after the repo updates.
Scripts are executed in order, after all management commands.
Scripts are executed in a context where the Python environment for the Django app is activated.
This attribute is included to support limited cases where an application can be deployed using only node attributes.

### Python

The version of Pip is fixed using a poise-python attribute.

* `default['poise-python']['options']['pip_version']`.
Defaults to '18.0'.
The version of Pip to install; Set to `true` for the latest.
As of poise-python v1.7.0, Pip 18.1 breaks the install, so this version should not be updated until poise-python is.

* `node['django_platform']['python']['packages_to_install']`.
Defaults to
```
{
  # These are included so that they can be upgraded; they are always installed on the first run
  pip: '',
  wheel: '',
  setuptools: '',
  # Pip install is used because CentOS/EPEL does not supply a package for WSGI that supports Python 3
  mod_wsgi: '',
  Django: ''
}
```
A Hash of package name to version.
If version is empty, the latest version will be installed
Clients should merge this attribute rather than overwrite because mod_wsgi and Django are required for the server to function.

### User

* `node['django_platform']['django_is_system_user']`.
Defaults to `true`.
If false, the django user will be configured with a shell, mostly for development and debugging.

# SSH private key for git user
* `node['django_platform']['git_ssh_key']['vault_data_bag']`.
Defaults to `nil`.
The name of the vault data bag from which to fetch the SSH key.
Must be set or an exception is raised.

* `node['django_platform']['git_ssh_key']['vault_bag_item']`.
Defaults to `nil`.
The item inside the data bag (json file).
Must be set or an exception is raised.

* `node['django_platform']['git_ssh_key']['vault_item_key']`.
Defaults to `nil`.
The hash key for referencing the SSH key within the json object.
Must be set or an exception is raised.

## Examples

This is an application cookbook; no custom resources are provided.
See recipes and attributes for details of what this cookbook does.

## Development

See CONTRIBUTING.md and TESTING.md.
