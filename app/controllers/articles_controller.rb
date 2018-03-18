class ArticlesController < ApplicationController
  def index
    @search_form = SearchForm.new(search_text)
    result = SearchQuery.new(@search_form).call
    @articles = result.articles
    @categories = result.categories
  end

  private

  def search_text
    params.dig(:search_form, :search_text)
  end
end
