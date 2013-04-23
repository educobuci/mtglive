require "active_support/all"

class Hash
  def self.from_json(json_string)
    ActiveSupport::JSON.decode(json_string)
  end
  def method_missing(method, *params)
    self[method.to_s] || self[method]
    # if self.has_key?(method.to_s) ||  self.has_key?(method)
    #   return 
    # end
    # super
  end
end