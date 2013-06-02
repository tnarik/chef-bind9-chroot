name             "bind9-chroot"
maintainer       "Tnarik Innael"
maintainer_email "tnarik@lecafeautomatique.co.uk"
license          "Apache 2.0"
description      "Installs/Configures bind9 with chroot and hiding CHAOS INFORMATION"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.4.1"

%w{ ubuntu debian centos }.each do |os|
  supports os
end
