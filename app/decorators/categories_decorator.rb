class CategoriesDecorator < Draper::CollectionDecorator
  def apply_counts(buckets_counts)
    each { |obj| obj.article_count = buckets_counts[obj.id] }
  end
end
