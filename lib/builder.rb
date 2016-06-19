require 'yaml'
require 'erb'
require 'fileutils'
require 'rdiscount'
require 'haml'
require 'json'
require 'awesome_print'

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
      @json_path = File.join(@root, 'json')
      @config = to_ostruct(YAML::load_file(File.join(@root, 'config.yml')))
    end

    def make_letter(source)

      @c = to_ostruct(YAML::load_file(File.join(@news_path, source)))
      if @c.rant.class == String
        @c.rant_html = RDiscount.new(@c.rant.to_s).to_html
        @c.rant_txt = wrap(@c.rant)
      elsif @c.rant
        @c.rant_html = RDiscount.new(@c.rant.content.to_s).to_html
        @c.rant_txt = wrap(@c.rant.content)
      end

      erb = ERB.new(File.read(File.join(@news_path, 'grn.html.erb')), 0, '<>')
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
      if @c.rant.class == String
        @c.rant_html = RDiscount.new(@c.rant.to_s).to_html
      elsif @c.rant
        @c.rant_html = RDiscount.new(@c.rant.content.to_s).to_html
      end

      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters[@c.edition] = { "link" => "grn-#{@c.edition}.html", "date" => @c.pubdate }
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
      page.letters = Hash[letters.sort_by { |edition,data| -edition.to_i }]
      page.config = @config
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
        letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
        page.letters = Hash[letters.sort_by { |edition,data| -(edition.to_i) }]
        page.config = @config
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
        partial = ERB.new(File.read(File.join(@news_path, 'grn-rss.erb')))
        tenletters = Hash[letters.to_a.reverse[0..9]]
        tenletters.each do |letter,c|
          maker.items.new_item do |item|
            item.link = "http://greenruby.org/#{c['link']}"
            item.guid.content = "http://greenruby.org/#{c['link']}"
            item.title = "Green Ruby News ##{letter}"
            item.updated = c['date']
            @c = to_ostruct(YAML::load_file(File.join(@news_path, "archives/grn-#{letter}.yml")))
            item.description = @c.edito
            item.content_encoded = partial.result(binding)
          end
        end
      end
      File.open(File.join(@static_path, "feed.rss"),'w') do |f|
        f.puts rss
      end
    end

    def make_json(edition = nil)
      issues = File.join(@json_path, "issues.json")
      stories = File.join(@json_path, "stories.json")
      issues_data = []
      stories_data = []
      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters.each do |letter,c|
        data = to_ostruct(YAML::load_file(File.join(@news_path, "archives/grn-#{letter}.yml")))
        issues_data << {
          "id" => data.edition.to_i,
          "date" => data.pubdate,
          "edito" => data.edito,
          "contributors" => data.contibutors
        }
        data.topics.each do |topic|
          topic.links.each do |story|
            stories_data << {
              "issue" => data.edition.to_i,
              "title" => story.title,
              "link" => story.url,
              "description" => story.comment,
              "category" => topic.title,
              "subject" => story.tags,
              "date" => story.pubdate,
              "quantity" => story.duration
            }
          end
        end
      end
      File.open(issues,'w') do |f|
        f.puts issues_data.to_json
      end
      File.open(stories,'w') do |f|
        f.puts stories_data.to_json
      end
    end


    def make_json_small(edition = nil)
      issues = File.join(@json_path, "issues_small.json")
      stories = File.join(@json_path, "stories_small.json")
      issues_data = []
      stories_data = []
      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters.each do |letter,c|
        data = to_ostruct(YAML::load_file(File.join(@news_path, "archives/grn-#{letter}.yml")))
        issues_data << {
          "i" => data.edition.to_i,
          "d" => data.pubdate,
          "e" => data.edito,
          "c" => data.contibutors
        }
        data.topics.each do |topic|
          topic.links.each do |story|
            stories_data << {
              "i" => data.edition.to_i,
              "t" => story.title,
              "l" => story.url,
              "d" => story.comment,
              "c" => topic.title,
              "s" => story.tags,
              "p" => story.pubdate,
              "q" => story.duration
            }
          end
        end
      end
      File.open(issues,'w') do |f|
        f.puts issues_data.to_json
      end
      File.open(stories,'w') do |f|
        f.puts stories_data.to_json
      end
    end

    def make_json_array
      issues = File.join(@json_path, "issues_array.json")
      stories = File.join(@json_path, "stories_array.json")
      issues_data = []
      stories_data = []
      letters = JSON.parse(File.read(File.join(@static_path, 'editions.json')))
      letters.each do |letter,c|
        data = to_ostruct(YAML::load_file(File.join(@news_path, "archives/grn-#{letter}.yml")))
        issues_data << [
          data.edition.to_i,
          data.pubdate,
          data.edito,
          data.contibutors
        ]
        data.topics.each do |topic|
          topic.links.each do |story|
            stories_data << [
              data.edition.to_i,
              story.title,
              story.url,
              story.comment,
              topic.title,
              story.tags,
              story.pubdate,
              story.duration
            ]
          end
        end
      end
      File.open(issues,'w') do |f|
        f.puts issues_data.to_json
      end
      File.open(stories,'w') do |f|
        f.puts stories_data.to_json
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

    def wrap(s, width=78)
      s.split("\n\n").collect! do |l|
        if /\[[-_0-9a-zA-Z]*\]:/.match l
          l
        else
          l.length > width ? l.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").strip : l
        end
      end * "\n\n"
    end

  end
end
