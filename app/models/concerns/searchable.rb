module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    def delete_document
      logger.debug ['Delating document... ', __elasticsearch__.delete_document].join
    end

    def index_document
      logger.debug ['Indexing document... ', __elasticsearch__.index_document].join
    end
  end

  module ClassMethods
    def recreate_index!
      __elasticsearch__.create_index! force: true
      __elasticsearch__.refresh_index!
    end
  end
end
