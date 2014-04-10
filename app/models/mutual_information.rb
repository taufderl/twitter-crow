class MutualInformation < ActiveRecord::Base
  belongs_to :user
  serialize :content, JSON
end
