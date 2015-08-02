#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright (C) 2014, 2015 Bloomberg Finance L.P.
#
require 'poise'

module ConsulCookbook
  module Resource
    # @since 1.0.0
    class ConsulConfig < Chef::Resource
      include Poise(fused: true)
      provides(:consul_config)

      # @!attribute path
      # @return [String]
      attribute(:path, kind_of: String, name_attribute: true)

      # @!attribute owner
      # @return [String]
      attribute(:user, kind_of: String, default: 'consul')

      # @!attribute group
      # @return [String]
      attribute(:group, kind_of: String, default: 'consul')

      # @!attribute bag_name
      # @return [String]
      attribute(:bag_name, kind_of: String, default: 'consul')

      # @!attribute bag_item
      # @return [String]
      attribute(:bag_item, kind_of: String, default: 'secrets')

      # @see: http://www.consul.io/docs/agent/options.html
      attribute(:acl_datacenter, kind_of: String)
      attribute(:acl_default_policy, kind_of: String)
      attribute(:acl_down_policy, kind_of: String)
      attribute(:acl_master_token, kind_of: String)
      attribute(:acl_token, kind_of: String)
      attribute(:acl_ttl, kind_of: String)
      attribute(:addresses, kind_of: [Hash, Mash])
      attribute(:advertise_addr, kind_of: String)
      attribute(:bind_addr, kind_of: String)
      attribute(:bootstrap, equal_to: [true, false], default: false)
      attribute(:bootstrap_expect, kind_of: Integer, default: 3)
      attribute(:ca_file, kind_of: String)
      attribute(:cert_file, kind_of: String)
      attribute(:check_update_interval, kind_of: String)
      attribute(:client_addr, kind_of: String)
      attribute(:data_dir, kind_of: String)
      attribute(:datacenter, kind_of: String)
      attribute(:disable_anonymous_signature, equal_to: [true, false], default: false)
      attribute(:disable_remote_exec, equal_to: [true, false], default: false)
      attribute(:disable_update_check, equal_to: [true, false], default: false)
      attribute(:dns_config, kind_of: [Hash, Mash])
      attribute(:domain, kind_of: String)
      attribute(:enable_debug, equal_to: [true, false], default: false)
      attribute(:enable_syslog, equal_to: [true, false], default: false)
      attribute(:encrypt, kind_of: String)
      attribute(:key_file, kind_of: String)
      attribute(:leave_on_terminate, equal_to: [true, false], default: false)
      attribute(:log_level, equal_to: %w(INFO DEBUG WARN), default: 'INFO')
      attribute(:node_name, kind_of: String)
      attribute(:ports, kind_of: [Hash, Mash])
      attribute(:protocol, kind_of: String)
      attribute(:recurser, kind_of: String)
      attribute(:retry_interval, kind_of: Integer)
      attribute(:server, equal_to: [true, false], default: true)
      attribute(:server_name, kind_of: String)
      attribute(:skip_leave_on_interrupt, equal_to: [true, false], default: false)
      attribute(:start_join, kind_of: Array)
      attribute(:rejoin_after_leave, kind_of:equal_to: [true, false], default: false)
      attribute(:statsd_addr, kind_of: String)
      attribute(:statsite_addr, kind_of: String)
      attribute(:syslog_facility, kind_of: String)
      attribute(:ui_dir, kind_of: String)
      attribute(:verify_incoming, equal_to: [true, false], default: false)
      attribute(:verify_outgoing, equal_to: [true, false], default: false)
      attribute(:verify_server_hostname, equal_to: [true, false], default: false)
      attribute(:watches, kind_of: [Hash, Mash], default: {})

      # Transforms the resource into a JSON format which matches the
      # Consul service's configuration format.
      def to_json
        for_keeps = %i{acl_datacenter acl_default_policy acl_down_policy acl_master_token acl_token acl_ttl addresses advertise_addr bind_addr bootstrap bootstrap_expect check_update_interval client_addr data_dir datacenter disable_anonymous_signature disable_remote_exec disable_update_check dns_config domain enable_debug enable_syslog encrypt leave_on_terminate log_level node_name ports protocol recurser retry_interval server server_name skip_leave_on_interrupt start_join rejoin_after_leave statsd_addr statsite_addr syslog_facility ui_dir verify_incoming verify_outgoing verify_server_hostname watches}
        for_keeps << %i{ca_file cert_file key_file} if tls?
        config = to_hash.keep_if do |k, _|
          for_keeps.include?(k.to_sym)
        end
        JSON.pretty_generate(config, quirks_mode: true)
      end

      def tls?
        verify_incoming || verify_outgoing
      end

      action(:create) do
        notifying_block do
          if new_resource.tls?
            include_recipe 'chef-vault::default'

            directory ::File.dirname(new_resource.ca_file) do
              recursive true
            end

            item = chef_vault_item(new_resource.bag_name, new_resource.bag_item)
            file new_resource.ca_file do
              content item['ca_certificate']
              mode '0644'
              owner new_resource.user
              group new_resource.group
            end

            directory ::File.dirname(new_resource.cert_file) do
              recursive true
            end

            file new_resource.cert_file do
              content item['certificate']
              mode '0644'
              owner new_resource.user
              group new_resource.group
            end

            directory ::File.dirname(new_resource.key_file) do
              recursive true
            end

            file new_resource.key_file do
              sensitive true
              content item['private_key']
              mode '0640'
              owner new_resource.user
              group new_resource.group
            end
          end

          directory ::File.dirname(new_resource.path) do
            recursive true
          end

          file new_resource.path do
            owner new_resource.user
            group new_resource.group
            content new_resource.to_json
            mode '0640'
          end
        end
      end

      action(:delete) do
        notifying_block do
          if new_resource.tls?
            file new_resource.cert_file do
              action :delete
            end

            file new_resource.key_file do
              action :delete
            end
          end

          file new_resource.path do
            action :delete
          end
        end
      end
    end
  end
end
