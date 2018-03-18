module Articles
  module Index
    extend ActiveSupport::Concern

    included do
      index_name "article-#{Rails.env}"

      settings index: { number_of_shards: 1 } do
        mappings dynamic: 'false' do
          indexes :name, type: :text, analyzer: 'english'
          indexes :author_name, type: :text, analyzer: 'english'
          indexes :category_names, type: :text, analyzer: 'english'
          indexes :category_ids, type: :integer
        end
      end
    end

    def as_indexed_json(*)
      {
        name: name,
        author_name: author_name,
        category_names: category_names,
        category_ids: category_ids
      }
    end

    private

    def category_names
      categories.pluck(:name).compact.uniq
    end

    def category_ids
      categories.pluck(:id).compact.uniq
    end
  end
end
