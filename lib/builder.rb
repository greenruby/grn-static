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
      @root = File.expand_path('../../../', __FILE__)
      @news_path = File.join(@root, 'newsletters')
      @views_path = File.join(@root, 'views')
      @pages_path = File.join(@root, 'app', 'pages')
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