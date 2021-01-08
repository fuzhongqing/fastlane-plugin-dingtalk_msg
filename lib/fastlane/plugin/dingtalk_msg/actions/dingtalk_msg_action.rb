require 'fastlane/action'
require_relative '../helper/dingtalk_msg_helper'

require 'uri'
require 'net/http'
require 'net/https'
require 'json'
require 'Base64'
require 'openssl'
require 'time'

module Fastlane
  module Actions
    class DingtalkMsgAction < Action

      # ACCEPT_TYPE = ['text', 'markdown', 'link', 'feed_card', 'action_card']
      ACCEPT_TYPE = ['text', 'markdown']

      def self.run(params)

        helper = Fastlane::Helper::DingtalkMsgHelper

        path = helper.assets(params[:type])

        if params[:template] != nil && File.exist?(params[:template]) then
          path = params[:template]
        end

        payload = params[:payload]

        payload[:message] ||= params[:message]
        payload[:atAll] ||= params[:atAll]
        payload[:title] ||= params[:title]
        payload[:atList] ||= params[:atList]

        self.send_msg(params[:access_token], params[:secret], JSON.parse(helper.render(path, payload)))
      end

      def self.send_msg(access_token, secret, message)

        if secret then

          timestamp = "#{(Time.now.to_f * 1000).to_i}"
          content = "#{timestamp}\n#{secret}".encode("utf-8")
          hash  = OpenSSL::HMAC.digest('sha256', secret, content)
          sign = Base64.strict_encode64(hash)

          params = { 
            'access_token' => access_token,
            'timestamp' => timestamp,
            'sign' => sign
          }
        else
          params = { 'access_token' => access_token }
        end

      
        uri = URI.parse('https://oapi.dingtalk.com/robot/send')
        uri.query = URI.encode_www_form(params)

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})

        req.body = message.to_json

        res = https.request(req)

        UI.error("#{res.body}") unless res.is_a?(Net::HTTPSuccess)
        json = JSON.parse(res.body)
        UI.error("#{json['errmsg'] }") unless json['errcode'].to_s == '0'

      end

      def self.description
        "dingtalk robot"
      end

      def self.authors
        ["fuzhongqing"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "发送消息到钉钉机器人，支持所有的发送模式，ERB模版，加密模式"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :access_token,
            env_name: "FL_DINGTALK_ACCESS_TOKEN",
            description: "access token",
            optional: true,
            default_value: nil 
          ),

          FastlaneCore::ConfigItem.new(key: :secret,
            env_name: "FL_DINGTALK_SECRET",
            description: "secret",
            optional: true,
            default_value: nil
          ),

          FastlaneCore::ConfigItem.new(key: :payload,
            description: "payload",
            optional: true,
            default_value: {},
            type: Hash
          ),

          FastlaneCore::ConfigItem.new(key: :type,
            description: "avaliable options: #{ACCEPT_TYPE}",
            optional: true,
            default_value: 'text',
            verify_block: lambda do |value|
              ACCEPT_TYPE.include? value
            end
          ),

          FastlaneCore::ConfigItem.new(key: :template,
            env_name: "FL_DINGTALK_TEMPLATE",
            description: "template",
            optional: true,
            default_value: nil,
            is_string: true
          ),

          FastlaneCore::ConfigItem.new(key: :message,
            optional: false,
            default_value: nil,
            is_string: true
          ),

          FastlaneCore::ConfigItem.new(key: :title,
            optional: true,
            default_value: "new message",
            is_string: true
          ),

          FastlaneCore::ConfigItem.new(key: :atAll,
            optional: true,
            default_value: false,
            type: Boolean
          ),

          FastlaneCore::ConfigItem.new(key: :atList,
            optional: true,
            default_value: [],
            type: Array
          ),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
