# frozen_string_literal: true

tcb = 'django_platform'

app_repo = node[tcb]['app_repo']

app_repo['additional_recipes_before_checkout'].each do |recipe|
  include_recipe recipe
end

directory '/opt/chef/idempotence'

host_content = 'This is a sentinel to detect new git hosts\n'
all_git_hosts.each do |host, _|
  ssh_known_hosts_entry host do
    host host
    file_location '/home/django/.ssh/known_hosts'
    owner django_user
    group django_group
  end
  file "/opt/chef/idempotence/known_host_#{host}.txt" do
    content "#{host_content}#{host}\n"
    mode '0644'
    # Write the entry to disk so the checkout succeeds the first time!
    notifies :flush, "ssh_known_hosts_entry[#{host}]", :immediate
  end
end

repo_url = "git@#{app_repo['git_host']}:#{app_repo['git_user']}/#{app_repo['git_repo']}"

git path_to_app_repo do
  user django_user
  group django_group
  repository repo_url
  # enable_checkout false # use checkout_branch
  revision app_repo['git_revision']
  enable_submodules true
  environment app_repo['environment']
  #notifies :restart, "service[#{apache_service}]", :delayed
  notifies :restart, "service[apache2]", :delayed
end

ruby_block 'Git Repo Synced' do
  block do
    node.default[tcb]['app_repo']['git_repo_updated'] = true
  end
  action :nothing
  subscribes :run, "git[#{path_to_app_repo}]", :immediate
end

app_repo['additional_recipes_before_install'].each do |recipe|
  include_recipe recipe
end

unless app_repo['rel_path_to_pip_requirements'].nil?
  pip_requirements 'Application requirements' do
    path File.join(path_to_app_repo, app_repo['rel_path_to_pip_requirements'])
    user django_user
    group django_group
    virtualenv path_to_venv
    only_if { node[tcb]['app_repo']['git_repo_updated'] }
  end
end

app_repo['additional_recipes_before_migration'].each do |recipe|
  include_recipe recipe
end

python_execute 'Migrate App Data' do
  command manage_command('migrate')
  cwd path_to_app_repo
  virtualenv path_to_venv
  user django_user
  group django_group
  only_if { node[tcb]['app_repo']['git_repo_updated'] }
end

python_execute 'Collect Static' do
  command manage_command('collectstatic --noinput')
  cwd path_to_app_repo
  virtualenv path_to_venv
  user django_user
  group django_group
  only_if { node[tcb]['app_repo']['git_repo_updated'] }
  only_if { File.open(path_to_settings_py).read =~ /\n\s*STATIC_ROOT/ }
end

app_repo['additional_management_commands'].each do |code|
  cmd = manage_command(code)
  python_execute "Manage Command: #{cmd}" do
    command cmd
    cwd path_to_app_repo
    virtualenv path_to_venv
    user django_user
    group django_group
    only_if { node[tcb]['app_repo']['git_repo_updated'] }
  end
end

app_repo['additional_shell_scripts'].each do |script|
  code = "source #{path_to_venv_activate}\n. #{script}"
  bash "Shell Script: #{script}" do
    code code
    cwd path_to_app_repo
    user django_user
    group django_group
    only_if { node[tcb]['app_repo']['git_repo_updated'] }
  end
end

# Django group must have write permissions in the directory and on the file
directory path_to_app_repo do
  user django_user
  group django_group
  mode '0770'
  only_if { app_repo['rel_path_to_sqlite_db'] }
end
file path_to_sqlite_db do
  user django_user
  group django_group
  mode '0660'
  only_if { app_repo['rel_path_to_sqlite_db'] }
end
