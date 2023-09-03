# frozen_string_literal: true

module Turnstile
  module Helpers
    DEFAULT_ERRORS = {
      turnstile_unreachable: 'Oops, we failed to validate your Turnstile response. Please try again.',
      verification_failed: 'Turnstile verification failed, please try again.'
    }.freeze
    DEFAULT_OPTIONS = {
      external_script: true,
      script: true,
      script_async: true,
      script_defer: true,
      theme: :auto
    }.freeze

    def self.turnstile(options)
      html = generate_tags(options)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.to_error_message(key)
      default = DEFAULT_ERRORS.fetch(key) { raise ArgumentError "Unknown Turnstile error - #{key}" }
      to_message("turnstile.errors.#{key}", default)
    end

    if defined?(I18n)
      def self.to_message(key, default)
        I18n.translate(key, default: default)
      end
    else
      def self.to_message(_key, default)
        default
      end
    end

    private_class_method def self.generate_tags(options)
      options = options.dup
      DEFAULT_OPTIONS.each do |name, value|
        options[name] = value unless options.key?(name)
      end
      generate_script_tag(options) + generate_placeholder_tag(options)
    end

    private_class_method def self.generate_script_tag(options)
      # Forge script URL
      url = Turnstile.configuration.api_server_url
      query_params = hash_to_query(
        onload: options.delete(:onload),
        render: options.delete(:render)
      )
      url += "?#{query_params}" unless query_params.empty?

      # Forge additional attributes
      async_attr = "async" if options.delete(:script_async)
      defer_attr = "defer" if options.delete(:script_defer)
      additional_attributes = [async_attr, defer_attr].compact.join(" ")

      return "" if options.delete(:script) == false || options.delete(:external_script) == false

      %(<script src="#{url}" #{additional_attributes}></script>)
    end

    private_class_method def self.generate_placeholder_tag(options)
      attributes = {}

      # Forge data-* attributes
      %i[
        action
        callback
        error_callback
        execution
        expired_callback
        before_interactive_callback
        after_interactive_callback
        unsupported_callback
        theme
        language
        tabindex
        timeout_callback
        response_field
        response_field_name
        size
        retry
        retry_interval
        refresh_expired
        appearance
      ].each do |data_attribute|
        value = options.delete(data_attribute)
        attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end
      attributes["data-sitekey"] = options.delete(:site_key) || Turnstile.configuration.site_key!
      attributes["data-cData"] = options.delete(:cdata)

      # Forge CSS classes
      attributes["class"] = ['cf-turnstile', options.delete(:class)].compact.join(' ')

      # Remaining options will be added as attributes on the tag.
      %(<div #{html_attributes(attributes)} #{html_attributes(options)}></div>)
    end

    private_class_method def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end

    private_class_method def self.html_attributes(hash)
      hash.map { |k, v| %(#{k}="#{v}") }.join(" ")
    end
  end
end
