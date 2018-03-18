## How to count articles in categories on search result using rails elastic aggregations and drapper

Have you ever need to calculate how many articles are in categories after search?
I'll show you how to use elastic aggregations to achieve this.

## Steps
I'll skip steps for creating app, and adding some layout
I'll use controller articles with action index for listing and search

### Install perequisities:
* elastic search or use docker image

* add these gems to Gemfile

    gem 'elasticsearch-model'
    gem 'elasticsearch-rails'
    gem 'draper', github: 'drapergem/draper'

* bundle install
* add elastic initializer to point elastic host

        config = {
          host: 'http://elasticsearch:9200',
          transport_options: {
            request: { timeout: 5 }
          }
        }
        Elasticsearch::Model.client = Elasticsearch::Client.new(config)

### Create models

        rails g model category name:string
        rails g model author name:string
        rails g model article name:string author:references
        rails g model article_category article:references category:references
        rake db:migrate
        rails generate draper:install

### create decorator for Category
        rails generate decorator Category

add `attr_accessor :article_count` to decorator class

### Create collection decorator
add method `apply_counts` with argument `buckets_counts`

        class CategoriesDecorator < Draper::CollectionDecorator
          def apply_counts(buckets_counts)
            each { |obj| obj.article_count = buckets_counts[obj.id] }
          end
        end

later this will allow to set article_count based on aggregations


### Add `module Searchable` to concerns

        module Searchable
          extend ActiveSupport::Concern

          included do
            include Elasticsearch::Model
            include Elasticsearch::Model::Callbacks

            def index_document
              __elasticsearch__.index_document
            end
          end

          module ClassMethods
            def recreate_index!
              __elasticsearch__.create_index! force: true
              __elasticsearch__.refresh_index!
            end
          end
        end



### In `Article` model

* include `Searchable
* add associations

        has_many :article_categories
        has_many :categories, through: :article_categories

* delegate  `author_name`

        delegate :name, to: :author, prefix: true

* in models folder create `Articles::Index` module to define elastic index

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

* `type: :text` are for text search
* `indexes :category_ids, type: :integer` will allow to aggregate results by category
* include `Articles::Index` in `Article` model

### Seed data
I've prepared seed with some jazz albums with assigned jazz sub-gneres.

    jazz = Category.create(name: 'jazz')
    fusion = Category.create(name: 'jazz fusion')
    bebop = Category.create(name: 'bebop')
    cool = Category.create(name: 'cool jazz')

    author = Author.create(name: 'Miles Davis')
    ['Bitches Brew', 'A Tribute to Jack Johnson', 'Miles In The Sky', 'Pangaea'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: fusion, article: article)
    end

    ['Kind of Blue', 'Sketches Of Spain', 'Birth of the Cool', 'Porgy And Bess'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: cool, article: article)
      ArticleCategory.create(category: bebop, article: article)
    end

    author = Author.create(name: 'Sonny Rollins')
    ['Sonny Rollins With The Modern Jazz Quartet'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: cool, article: article)
    end

    ['Next Album', 'Easy Living', 'The Way I Feel ', "Don't Stop the Carnival"].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: fusion, article: article)
    end

    ['Saxophone Colossus', 'Plus Three'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: bebop, article: article)
    end

    author = Author.create(name: 'Chet Baker')
    ['Chet', 'My Funny Valentine'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: cool, article: article)
    end

    author = Author.create(name: 'Paul Desmond')
    ['Feeling Blue', 'Bossa Antigua', "We're all together again"].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: cool, article: article)
    end

    author = Author.create(name: 'Dave Brubeck')
    ['Concord on a Summer Night', 'Time Further Out', "Time Out"].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: cool, article: article)
    end

    author = Author.create(name: 'The Mahavishnu Orchestra')
    ['Birds Of Fire', 'Between Nothingness & Eternity', 'The Inner Mounting Flame'].each do |title|
      article = Article.create(name: title, author: author )
      ArticleCategory.create(category: jazz, article: article)
      ArticleCategory.create(category: fusion, article: article)
    end

    Article.recreate_index!
    Article.import

the last two lines in seed create index in elastic so

    rake db:seed

### now we can take care of searching and aggregates
### Add simple class for search form

    class SearchForm
      include ActiveModel::Model

      attr_reader :search_text

      def initialize(search_text)
        @search_text = search_text
      end
    end

### Add search query object

    class SearchQuery
      def initialize(search_form)
        @search_form = search_form
      end

      def call
        Article.search(search_text).records.to_a
      end

      private

      attr_reader :search_form

      delegate :search_text, to: :search_form
    end

search with elastic could be as simple as `Article.search(search_text).records.to_a`
but we can ask **elastic**  to count something for us in one go
so we will need a little bit more complex query which we'll prepare using elastic DSL and put as an argument to `search` method

**all beneath methods are private**

* search definition object will do almost the same as above search

          def query
            {
              size: 100,
              from: 0,
              query: simple_query
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

* attributes `:size`, `:from` are for paging, default elastic page size is 10
* how to add aggregations? using elastic DSL we can define aggs criteria:

            def aggs_categories
              {
                by_categories:{
                  terms:{
                    field: :category_ids
                  }
                }
              }
            end

* and ad them to search definition object:

            def query
              {
                size: 100,
                from: 0,
                query: simple_query,
                aggs: aggs_categories
              }
            end

* result of our query object at the end should look like a.e.

        {
          :size => 100,
          :from => 0,
          :query => {
            :query_string => {
              :query => "*miles*"
              }
            },
          :aggs => {
            :by_categories => {
              :terms=> { :field =>: category_ids }
            }
          }
        }

* when we assign search object to `search` variable as `search = Article.search(query)` then we check  `search.response` on search object which should look like

            {
              "took"=>62,
              "timed_out"=>false,
              "_shards"=>{"total"=>1, "successful"=>1, "skipped"=>0, "failed"=>0},
              "hits"=> {
                "total"=> 8,
                "max_score" => 1.0,
                "hits" => [
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"1", "_score"=>1.0, "_source"=>{"name"=>"Bitches Brew", "author_name"=>"Miles Davis", "category_names"=>["jazz", "jazz fusion"], "category_ids"=>[1, 2]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"2", "_score"=>1.0, "_source"=>{"name"=>"A Tribute to Jack Johnson", "author_name"=>"Miles Davis", "category_names"=>["jazz", "jazz fusion"], "category_ids"=>[1, 2]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"3", "_score"=>1.0, "_source"=>{"name"=>"Miles In The Sky", "author_name"=>"Miles Davis", "category_names"=>["jazz", "jazz fusion"], "category_ids"=>[1, 2]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"4", "_score"=>1.0, "_source"=>{"name"=>"Pangaea", "author_name"=>"Miles Davis", "category_names"=>["jazz", "jazz fusion"], "category_ids"=>[1, 2]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"5", "_score"=>1.0, "_source"=>{"name"=>"Kind of Blue", "author_name"=>"Miles Davis", "category_names"=>["jazz", "bebop", "cool jazz"], "category_ids"=>[1, 3, 4]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"6", "_score"=>1.0, "_source"=>{"name"=>"Sketches Of Spain", "author_name"=>"Miles Davis", "category_names"=>["jazz", "bebop", "cool jazz"], "category_ids"=>[1, 3, 4]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"7", "_score"=>1.0, "_source"=>{"name"=>"Birth of the Cool", "author_name"=>"Miles Davis", "category_names"=>["jazz", "bebop", "cool jazz"], "category_ids"=>[1, 3, 4]}},
                  {"_index"=>"article-development", "_type"=>"article", "_id"=>"8", "_score"=>1.0, "_source"=>{"name"=>"Porgy And Bess", "author_name"=>"Miles Davis", "category_names"=>["jazz", "bebop", "cool jazz"], "category_ids"=>[1, 3, 4]}}
                ]
              },
              "aggregations" => {
                "by_categories" => {
                  "doc_count_error_upper_bound"=>0,
                  "sum_other_doc_count"=>0,
                  "buckets"=>[
                    {"key"=>1, "doc_count"=>8},
                    {"key"=>2, "doc_count"=>4},
                    {"key"=>3, "doc_count"=>4},
                    {"key"=>4, "doc_count"=>4}
                  ]
                }
              }
            }

* in `"aggregations" => "by_categories"` we can find `"buckets"`, that's what we're interested in! Key `"buckets"` contain counts for category_ids

* extract them:

        def buckets_categories_counts
          @categories_counts ||= search.response
                                       .deep_symbolize_keys[:aggregations][:by_categories][:buckets]
                                       .map{ |bucket| OpenStruct.new(bucket) }
        end
* map categories_ids:

        def buckets_categories_ids
          buckets_categories_counts.map(&:key)
        end

* prepare bucket hash

        def buckets_hash
          buckets_categories_counts.each_with_object({}) do |bucket, obj|
            obj[bucket.key]= bucket.doc_count
          end
        end

* find categories, decorate collection and apply counts

        def categories
          ::CategoriesDecorator.decorate(
            Category.where(id: buckets_categories_ids)
          ).apply_counts(buckets_hash)
        end


### Update public method `call`

         def call
           OpenStruct.new(
             categories: categories,
             articles: search.records.order('articles.name asc').includes(:author).to_a
           )
         end

we will return object with categories and articles

### Last step add some logic to `ArticlesController`

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

## Working app
That's all you can check working example downloading repo
* clone or download repo
* install docker if needed
* run

        docker-compose build
        docker-compose run web bundle install
        docker-compose run web rake db:create db:migrate db:seed