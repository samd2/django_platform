# frozen_string_literal: true

include_recipe 'http_platform::default'

# Apache cookbook mod_wsgi does not support Python 3
# This is used for pip install of wsgi
package apache_dev_package_name

var_map = {
  path_to_manage_dir: File.join(path_to_app_repo, rel_path_to_manage_directory),
  path_to_static_directory: File.join(path_to_app_repo, rel_path_to_static_directory),
  path_to_venv: path_to_venv,
  path_to_wsgi_py: File.join(path_to_app_repo, rel_path_to_site_directory, 'wsgi.py')
}

template 'Django Host' do
  path File.join(config_absolute_directory, 'django-host.conf')
  source 'django-host.conf.erb'
  variables var_map
  owner 'root'
  group 'root'
  mode '0440'
  #notifies :restart, "service[#{apache_service}]", :delayed
  notifies :restart, "service[apache2]", :delayed
end

django_conf = File.join(conf_available_directory, 'django.conf')

# We use template because apache_conf does not support variables
template 'Django Conf' do
  path django_conf
  source 'django.conf.erb'
  variables var_map
  owner 'root'
  group 'root'
  mode '0440'
  #notifies :restart, "service[#{apache_service}]", :delayed
  notifies :restart, "service[apache2]", :delayed
end

link 'Link for Django Conf' do
  target_file File.join(conf_enabled_directory, 'django.conf')
  to django_conf
  owner 'root'
  group 'root'
  #notifies :restart, "service[#{apache_service}]", :delayed
  notifies :restart, "service[apache2]", :delayed
end
