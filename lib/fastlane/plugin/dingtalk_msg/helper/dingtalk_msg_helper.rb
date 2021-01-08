require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DingtalkMsgHelper
      # class methods that you define here become available in your action
      # as `Helper::DingtalkMsgHelper.your_method`
      #
      require "erb"

      def self.assets(name)
        "#{gem_path('fastlane-plugin-dingtalk_msg')}/lib/assets/#{name}.erb"
      end

      def self.render(template, template_vars_hash)
        Fastlane::ErbalT.new(template_vars_hash).render(File.read(template))
      end

      #
      # Taken from https://github.com/fastlane/fastlane/blob/f0dd4d0f4ecc74d9f7f62e0efc33091d975f2043/fastlane_core/lib/fastlane_core/helper.rb#L248-L259
      # Unsure best other way to do this so using this logic for now since its deprecated in fastlane proper
      #
      def self.gem_path(gem_name)
        if !Helper.is_test? and Gem::Specification.find_all_by_name(gem_name).any?
          return Gem::Specification.find_by_name(gem_name).gem_dir
        else
          return './'
        end
      end
    end
  end
end
