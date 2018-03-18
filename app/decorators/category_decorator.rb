class CategoryDecorator < Draper::Decorator
  delegate_all

  attr_accessor :article_count
end
