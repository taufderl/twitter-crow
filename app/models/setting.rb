class Setting < ActiveRecord::Base
  self.inheritance_column = :_type_disabled
  
  TYPES = [:string, :integer, :float]
  
  def self.get(setting_key)
    setting = find_by_key(setting_key)
    setting.get_value
  end
  
  def self.TYPES 
    TYPES
  end
  
  def get_value
    case type
    when 'string'
      return value
    when 'integer'
      return value.to_i
    when 'float'
      return value.to_f
    else
      return 'invalid type'
    end
  end
  
end
