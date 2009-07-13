module ActsAsUrl
  
  def self.included(base)
    base.send(:extend, ClassMethods)
  end
  
  mattr_accessor :default_protocols
  self.default_protocols = %w( http https )
  
  module ClassMethods
    URL_SUBDOMAINS_PATTERN = '(?:[-\w]+\.)+'
    URL_TLD_PATTERN        = '[a-z]{2,6}'
    URL_PORT_PATTERN       = '(?::\d{1,5})?'
    
    attr_accessor :protocols
    
    def acts_as_url(*attributes)
      self.protocols = attributes.extract_options!
      attributes += protocols.keys
      
      attributes.each do |attribute|
        # Set default protocols
        self.protocols[attribute] ||= ActsAsUrl.default_protocols
        
        add_url_validation(attribute, self.protocols[attribute].to_a)
        
        # Define before save callback
        callback_name = "convert_#{attribute}_to_url".to_sym
        before_save callback_name
        define_method callback_name do
          write_attr_as_url(attribute)
        end
        
        # Define reader method
        define_method(attribute) do
          url = read_attribute(attribute)
          
          # Shorthand for URI.parse(url)
          def url.to_uri
            URI.parse(self)
          end
          
          url
        end
      end
      
      send(:include, InstanceMethods)
    end
    
    private
    def add_url_validation(attribute, protocols)
      validates_format_of(attribute, :with => /\A(?:(?:#{protocols.join('|')}):\/\/)?#{URL_SUBDOMAINS_PATTERN + URL_TLD_PATTERN + URL_PORT_PATTERN}(?:\/\S*)?\z/, :allow_blank => true)
    end
    
  end
  
  module InstanceMethods
    
    private
    def write_attr_as_url(attribute)
      url = self.send(attribute)
      self.send((attribute.to_s + '=').to_sym, convert_to_url(attribute, url))
    end
    
    def convert_to_url(attribute, url)
      # Don't try to convert an empty string to a url
      return url if url.blank?
      
      # Get provided protocol if any
      provided_protocol = self.class.protocols[attribute].to_a.reject { |p| !url.starts_with?(p + '://') }.first
      protocol_included = !provided_protocol.nil?
      
      # Make sure the host name is appended by a slash
      url += '/' unless (protocol_included ? url_without_protocol(url, provided_protocol + '://') : url).include?('/')
      # Add protocol to url if missing
      url = self.class.protocols[attribute].to_a.first + '://' + url unless protocol_included
      
      return url
    end
    
    def url_without_protocol(url, protocol)
      url[protocol.length, url.length - protocol.length]
    end
    
  end
  
end
