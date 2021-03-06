class Site < ApplicationRecord
  has_many :site_user
  has_many :users, through: :site_user
  has_many :groups
  has_many :network_site
  has_many :networks, through: :network_site
end
