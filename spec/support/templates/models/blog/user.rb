class Blog::User < ActiveRecord::Base
  has_many :posts, foreign_key: 'author_id'
  accepts_nested_attributes_for :posts, allow_destroy: true

  def display_name
    "#{first_name} #{last_name}"
  end
end
