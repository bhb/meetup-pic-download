# ruby download.rb email first_pic_url
require "rubygems"
require "bundler/setup"
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require 'highline/import'

email = ARGV.shift
album_url = ARGV.shift

def get_password(prompt="Enter Password:")
  ask(prompt) {|q| q.echo = "*"}
end

password = get_password

dir = File.expand_path(File.join(File.dirname(__FILE__), "pics"))
unless File.exists?(dir)
  puts "Creating pics dir"
  FileUtils.mkdir dir
end

def download_file(dir, url)
  filename = url.split('/').last
  file_path = File.join(dir, filename)
  if File.exists?(File.join(dir, filename))
    puts "Found #{filename}. Skipping ... "
  else
    puts "Downloading #{url} ... "
    open(file_path, 'wb') do |file|
      file << open(url).read
    end
  end
end

def last_image?(page)
  text = page.search('//*[@id="D_photoGallery_currentPhotoCounter"]').inner_text
  number, total = text.split('of').map(&:to_i)
  number >= total
end

puts "Looking for photos starting with #{album_url}"

puts "Logging in ...."
agent = Mechanize.new
login_page = agent.get("https://secure.meetup.com/login/")

login_form = login_page.form
login_form.email = email
login_form.password = password
agent.submit(login_form)

puts "Logged in."

page = agent.get(album_url)

until last_image?(page)
  high_res_link = page.search('//*[@id="D_photoGallery_allSizesUrls"]/li[5]/a').first['href']
  puts "Found high-res image: #{high_res_link}"
  download_file(dir, high_res_link)

  next_photo_link = page.search('//*[@id="D_photoGallery_actionsNext"]').first['href']
  puts "Found next photo link: #{next_photo_link}"
  page = agent.get(next_photo_link)
end

puts "Done."
