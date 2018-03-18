class SearchQuery
  def initialize(search_form)
    @search_form = search_form
  end

  def call
    OpenStruct.new(
      categories: categories,
      articles: search.records.order('articles.name asc').includes(:author).to_a
    )
  end

  private

  attr_reader :search_form

  delegate :search_text, to: :search_form

  def search
    @search ||= Article.search(query)
  end

  def buckets_categories_counts
    @categories_counts ||= search.response
                                 .deep_symbolize_keys[:aggregations][:by_categories][:buckets]
                                 .map{ |bucket| OpenStruct.new(bucket) }
  end

  def buckets_categories_ids
    buckets_categories_counts.map(&:key)
  end

  def buckets_hash
    buckets_categories_counts.each_with_object({}) do |bucket, obj|
      obj[bucket.key]= bucket.doc_count
    end
  end

  def categories
    CategoriesDecorator.decorate(
      Category.where(id: buckets_categories_ids)
    ).apply_counts(buckets_hash)
  end

  def query
    {
      size: 100,
      from: 0,
      query: simple_query,
      aggs: aggs_categories
    }
  end

  def match_all
    { match_all: {} }
  end

  def simple_query
    return match_all if search_text.blank?
    {
      query_string: {
        query: add_wildcards(search_text)
      }
    }
  end

  def add_wildcards(text)
    text.split(' ').map { |el| "*#{el}*" }.join(' ')
  end

  def aggs_categories
    {
      by_categories:{
        terms:{
          field: :category_ids
        }
      }
    }
  end
end
