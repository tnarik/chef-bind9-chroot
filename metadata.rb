name             'bind9-chroot'
maintainer       'Tnarik Innael'
maintainer_email 'tnarik@lecafeautomatique.co.uk'
license          'apache2'
description      'Installs/Configures bind9 with chroot and hiding CHAOS INFORMATION'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url       'https://github.com/tnarik/chef-bind9-chroot'
issues_url       'https://github.com/tnarik/chef-bind9-chroot/issues'
version          '0.4.2'

%w{resolvconf}.each do |cookbook|
  depends cookbook
end

%w{ubuntu debian centos}.each do |os|
  supports os
end
