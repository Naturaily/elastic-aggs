# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

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
