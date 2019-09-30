# frozen_string_literal: true

name 'django_platform'
maintainer 'OIT Systems Engineering'
maintainer_email 'ua-oit-se@alaska.edu'
license 'MIT'
description 'Installs/configures the platform and deploys a Django application from a git repository'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

git_url = 'https://github.com/ualaska-it/django_platform'
source_url git_url if respond_to?(:source_url)
issues_url "#{git_url}/issues" if respond_to?(:issues_url)

version '1.0.1'

supports 'ubuntu', '>= 16.0'
supports 'centos', '>= 7.0'

chef_version '>= 14.0' if respond_to?(:chef_version)

depends 'apache2', '6.0.0'
depends 'chef-vault'
depends 'http_platform'
depends 'poise-python'
depends 'postgresql'
depends 'yum-epel'
