#Description

This cookbook takes care of the installation and configuration of BIND9. You're able to define some global variables and manage your zonefiles via data bags (json example below).
It also supports automatic serial number generation and automatic resource records for chef nodes (see optional json in example below)
No DNSSEC, no configurable logging, no rndc shell operations or other safety checks (named-checkconf, etc.).

If you want to help feel free to contribute (either here or at [Mike Adolphs's cookbook](https://github.com/fooforge/chef-cookbook_bind9), which this is based on)!

**DISCLAIMER**:  
It works on my setup!

#Requirements

Platform:

* Debian
* Ubuntu
* Centos

#Attributes

It's so much better if you take a look at the ```attributes/default.rb``` file for the full list, but this is a brief summary:

* **node[:bind9][:enable_ipv6]**       - Enables BIND to listen on an IPv6 address. Default is: On
* **node[:bind9][:allow_query]**       - Allow clients to query the nameserver. Default is: none
* **node[:bind9][:allow_recursion]**   - Allow recursive name resolution. Default is: none (to prevent DNS cache poisoning)
* **node[:bind9][:allow_update]**      - Allow dynamic DNS updates. Default is: none
* **node[:bind9][:allow_transfer]**    - Allow zone transfers globally. Default is: none
* **node[:bind9][:enable_forwarding]** - Enables forwarding of requests. Default is: No forwarding
* **node[:bind9][:forwarders]**        - Array for forwarding DNS. Default is: 8.8.4.4 and 8.8.8.8 (Google DNS)
* **node[:bind9][:chroot_dir]** - Enables running in a chroot'ed environment. Default is: no chroot'ing
* **node[:bind9][:disclose]** - Enables disclosing CHAOS information. Default is: false


#Usage

Add ```"recipe[bind9-chroot]"``` to your run list. If you want to use BIND9 for serving domains you need add the appropriate data via data bags (example below).
Please note that the data bag's structure is mandatory except: 

* TTL for DNS records (if you decide to leave it empty, the global TTL will take over).
* IP for DNS records (if not available, ```node['ipaddress']``` will be used).

In order to run a a chroot'ed Bind9 server, set the ```node[:bind9][:chroot_dir]``` to the desired chroot path and optionally the ```node[:bind9][:disclose]``` attributes.

To use this cookbook with Chef Solo, add ```"recipe[chef-solo-search]"``` to your run list, and create the data bags either manually or using the ```knife-solo_data_bag``` gem.

#Examples

To create and view the data bags:

    $ knife data bag create zones
    $ knife data bag create zones exampleDOTcom
    $ ... do something ...
    $ knife data bag from file zones exampleDOTcom.json

An example of a data bag with mail records and specific IPs.

    {
      "id": "exampleDOTcom",
      "domain": "example.com",
      "type": "master",
      "allow_transfer": [ "8.8.4.4",
                          "8.8.8.8" ],
      "zone_info": {
        "global_ttl": 300,
        "soa": "ns.example.com.",
        "contact": "user.example.com.",
        "nameserver": [ "ns.example.com.",
                        "ns.example.net." ],
        "mail_exchange": [{
          "host": "ASPMX.L.GOOGLE.COM.",
          "priority": 10
        },{
          "host": "ALT1.ASPMX.L.GOOGLE.COM.",
          "priority": 20
        },{
          "host": "ALT2.ASPMX.L.GOOGLE.COM.",
          "priority": 20
        },{
          "host": "ASPMX2.GOOGLEMAIL.COM.",
          "priority": 30
        },{
          "host": "ASPMX3.GOOGLEMAIL.COM.",
          "priority": 30
        },{
          "host": "ASPMX4.GOOGLEMAIL.COM.",
          "priority": 30
        },{
          "host": "ASPMX5.GOOGLEMAIL.COM.",
          "priority": 30
        }],
        "records": [{
          "name": "www",
          "type": "A",
          "ip": "127.0.0.1"
        },{
          "name": "img",
          "ttl": 30,
          "type": "A",
          "ip": "127.0.0.1"
        },{
          "name": "mail",
          "type": "CNAME",
          "ip": "ghs.google.com."
        }]
      }
    }

An example of a data bag with mail records and specific IPs.

    {
      "id": "exampleDOTcom",
      "domain": "example.com",
      "type": "master",
      "allow_transfer": [],
      "zone_info": {
        "global_ttl": 300,
        "soa": "ns.example.com.",
        "contact": "user.example.com.",
        "nameserver": [ "ns.example.com.",
                        "ns.example.net." ],
        "mail_exchange": [],
        "records": [{
          "name": "www",
          "type": "A"
         },{
          "name": "img",
          "ttl": 30,
          "type": "A"
        },{
          "name": "mail",
          "type": "CNAME"
        }]
      }
    }
    
#Contributions

This cookbook is derived from [Mike Adolphs's](https://github.com/fooforge/chef-cookbook_bind9), and specific contributions can be tracked via git.