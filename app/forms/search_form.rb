class SearchForm
  include ActiveModel::Model

  attr_reader :search_text

  def initialize(search_text)
    @search_text = search_text
  end
end
