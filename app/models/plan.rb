class Plan < ActiveRecord::Base
  belongs_to :user
  DEFAULT_SIZE = 128
end
