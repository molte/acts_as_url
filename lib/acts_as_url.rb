module ActsAsUrl
  
  def self.included(base)
    base.send(:extend, ClassMethods)
  end
  
  module ClassMethods
    DEFAULT_ALLOWED_PROTOCOLS = %w( http https )
    
    URL_SUBDOMAINS_PATTERN = '([-\w]+\.)+'
    URL_TLD_PATTERN        = '[a-z]{2,6}'
    URL_PORT_PATTERN       = '(:\d{1,5})?'
    
    def acts_as_url(*attributes)
      protocols = attributes.last.is_a?(Hash) ? attributes.pop : {}
      attributes += protocols.keys
      
      attributes.each do |attribute|
        # Set default protocols
        protocols[attribute] ||= DEFAULT_ALLOWED_PROTOCOLS
        # Append "://" to each protocol
        protocols[attribute] = protocols[attribute].to_a.collect { |p| p + '://' }
        
        add_url_validation(attribute, protocols[attribute])
        
        # Define writer method
        define_method((attribute.to_s + '=').to_sym) do |url|
          # Don't convert an empty string to a url
          write_attribute(attribute, url) and return if url.blank?
          
          # Get provided protocol if any
          provided_protocol = protocols[attribute].reject { |p| !url.starts_with?(p) }.first
          protocol_included = !provided_protocol.nil?
          
          # Make sure the host name is appended by a slash
          url += '/' unless (protocol_included ? url[provided_protocol.length, url.length - provided_protocol.length] : url).include?('/')
          # Add protocol to url if missing
          url = protocols[attribute].first + url unless protocol_included
          
          write_attribute(attribute, url)
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
    end
    
    private
    def add_url_validation(attribute, protocols)
      validates_format_of(attribute, :with => /\A(#{protocols.join('|')})#{URL_SUBDOMAINS_PATTERN + URL_TLD_PATTERN + URL_PORT_PATTERN}\/\S*\z/, :allow_blank => true)
    end
    
  end
  
end
