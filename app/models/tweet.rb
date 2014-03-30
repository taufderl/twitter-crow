class Tweet < ActiveRecord::Base
  validates_uniqueness_of :id
  belongs_to :user
  
  def coordinates
    return [geo_latitude, geo_longitude]
  end
  
  def to_s
    created_at.to_s + ":\n" + text 
  end
end
