# frozen_string_literal: true

tcb = 'django_platform'

# '3' works in CentOS 7 but not Ubuntu 18 as of August 2018
if platform_family?('debian')
  python_runtime '3' do
    options package_name: 'python3'
  end
else
  python_runtime '3'
end

python_virtualenv '/home/django/env' do
  user 'django'
  group 'django'
  python '3'
end

git '/home/django/app' do
  user 'django'
  group 'django'
  repository node[tcb]['app_repo']['repository']
  # enable_checkout false # use checkout_branch
  revision node[tcb]['app_repo']['revision']
  enable_submodules true
  environment node[tcb]['app_repo']['environment']
  notifies :restart, "service[#{apache_service}]", :delayed
end
