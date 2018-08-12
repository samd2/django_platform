# frozen_string_literal: true

# '3' works in CentOS 7 but not Ubuntu 18 as of August 2018
if platform_family?('debian')
  python_runtime '3' do
    options package_name: 'python3'
  end
else
  python_runtime '3'
end
