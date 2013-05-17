module LeCafeAutomatique
  module Bind9
    module NameServer
      def self.included(base)
        base.extend(ClassMethods)
      end

    module ClassMethods
      def nameserver_proxy(file, regex)
        nameservers = File.read(file).match(regex)
        nameserver_proxy = nameservers ? nameservers[0] : ""
      end
    end
  end
end
end

# open the Chef::Recipe class and mix in the library module
#£class Chef::Recipe::NameServer
# include Chef::Bind9::NameServer
#end
#
#
#class Bind9
#  class Nameserver
#    def self.nameserver_proxy(file, regex)
#      nameservers = File.read(file).match(regex)
#      nameserver_proxy = nameservers ? nameservers[0] : ""
#    end
#  end
#end
