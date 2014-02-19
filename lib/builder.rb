require 'yaml'
require 'erb'
require 'fileutils'
require 'rdiscount'
require 'haml'
require 'json'

YAML::ENGINE.yamler = 'psych'

module Greeby

  module Binding

  end

  class Builder

    attr_reader :c

    def initialize
      @root = File.expand_path('../../', __FILE__)
      @news_path = File.join(@root, 'newsletters')
      @views_path = File.join(@root, 'views')
      @pages_path = File.join(@root, 'pages')
      @static_path = File.join(@root, 'site')
    end

    def make_letter(source)

      @c = to_ostruct(YAML::load_file(File.join(@news_path, source)))

      erb = ERB.new(File.read(File.join(@news_path, 'grn.html.erb')))
      File.open(File.join(@news_path, 'html', "GRN-#{@c.edition}.html"), 'w') do |f|
        f.puts erb.result(binding)
      end
      txt = ERB.new(File.read(File.join(@news_path, 'grn.txt.erb')))
      File.open(File.join(@news_path, 'txt', "GRN-#{@c.edition}.txt"), 'w') do |f|
        f.puts txt.result(binding)
      end
      FileUtils.cp(
        File.join(@news_path, 'grn.yml'),
        File.join(@news_path, 'archives', "grn-#{@c.edition}.yml")
      )
    end

    def make_archives(source)

      @c = to_ostruct(YAML::load_file(File.join(@news_path, source)))

      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters[@c.edition] = { link: "grn-#{@c.edition}.html", date: @c.pubdate }
      File.open(File.join(@static_path, 'editions.json'),'w') do |f|
        f.puts letters.to_json
      end

      partial = ERB.new(File.read(File.join(@news_path, 'grn-partial.erb')))
      File.open(File.join(@news_path, 'partials', "GRN-#{@c.edition}.html"), 'w') do |f|
        f.puts partial.result(binding)
      end

      template = File.read(File.join(@views_path, 'static.haml'))
      haml_engine = Haml::Engine.new(template)
      page = OpenStruct.new
      page.letters = letters
      page.name = @c.edition
      page.content = File.read(File.join(@news_path, 'partials', "GRN-#{@c.edition}.html"))
      html = haml_engine.render(page)
      File.open(File.join(@static_path, "grn-#{page.name}.html"),'w') do |f|
        f.puts html
      end
      File.open(File.join(@static_path, 'index.html'),'w') do |f|
        f.puts html
      end
    end

    def make_all
      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters.each do |letter,c|
        make_archives("archives/grn-#{letter}.yml")
      end
    end

    def make_web
      template = File.read(File.join(@views_path, 'static.haml'))
      haml_engine = Haml::Engine.new(template)
      pages = Dir.glob(File.join(@pages_path, '*.md'))
      pages.each do |p|
        page = OpenStruct.new
        page.name = File.basename(p, '.md')
        page.content = RDiscount.new(File.read(p)).to_html
        html = haml_engine.render(page)
        File.open(File.join(@static_path, "#{page.name}.html"),'w') do |f|
          f.puts html
        end
      end
    end

    def make_rss
      require "rss"
      rss = RSS::Maker.make("2.0") do |maker|
        maker.channel.author = "mose"
        maker.channel.updated = Time.now.to_s
        maker.channel.description = "Green Ruby News is a feed of fresh links of the week about ruby, javascript, webdev, devops, collected by mose every sunday"
        maker.channel.title = "Green Ruby"
        maker.channel.link = "http://greenruby.org/feed.rss"
        maker.channel.language = "en-US"

        letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
        tenletters = Hash[letters.to_a.reverse[0..9]]
        tenletters.each do |letter,c|
          maker.items.new_item do |item|
            item.link = "http://greenruby.org/#{c['link']}"
            item.guid.content = "http://greenruby.org/#{c['link']}"
            item.title = "Green Ruby News ##{letter}"
            item.updated = c['date']
            content = to_ostruct(YAML::load_file(File.join(@news_path, "archives/grn-#{letter}.yml")))
            item.description = content.edito
            item.content_encoded = File.read(File.join(@news_path, "partials/GRN-#{letter}.html"))
          end
        end
      end
      File.open(File.join(@static_path, "feed.rss"),'w') do |f|
        f.puts rss
      end
    end

    private

    def to_ostruct(obj)
      result = obj
      if result.is_a? Hash
        result = result.dup
        result.each do |key, val|
          result[key] = to_ostruct(val)
        end
        result = OpenStruct.new result
      elsif result.is_a? Array
        result = result.map { |r| to_ostruct(r) }
      end
      return result
    end

  end
end
