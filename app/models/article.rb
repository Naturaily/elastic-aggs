class Article < ApplicationRecord
  include Searchable
  include Articles::Index
  belongs_to :author
  has_many :article_categories
  has_many :categories, through: :article_categories

  delegate :name, to: :author, prefix: true
end
