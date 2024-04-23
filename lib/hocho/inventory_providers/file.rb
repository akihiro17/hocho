require 'hocho/utils/symbolize'
require 'hocho/inventory_providers/base'
require 'hocho/host'
require 'yaml'

module Hocho
  module InventoryProviders
    class File < Base
      def initialize(path:)
        @path = path
      end

      attr_reader :path

      def files
        @files ||= case
        when ::File.directory?(path)
          Dir[::File.join(path, "*.yml")]
        else
          [path]
        end
      end

      def hosts
        @hosts ||= files.flat_map do |file|
          content = Hocho::Utils::Symbolize.keys_of(
            YAML.safe_load_file(
              file,
              permitted_classes: [Symbol, Net::SSH::Proxy::Jump, Net::SSH::Proxy::Command]),
          )
          content.map do |name, value|
            Host.new(
              name.to_s,
              providers: self.class,
              properties: value[:properties] || {},
              tags: value[:tags] || {},
              ssh_options: value[:ssh_options],
            )
          end
        end
      end
    end
  end
end
