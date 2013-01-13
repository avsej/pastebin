require 'rubygems'
require 'securerandom'
require 'fileutils'
require 'bundler'
Bundler.require

BASE = "http://paste.avsej.net"
STORE = File.expand_path("tmp/files", File.dirname(__FILE__))
FileUtils.mkdir_p(STORE)

not_found do
  content_type "text/plain"
  "not found\n"
end

error do
  content_type "text/plain"
  "error\n"
end

before do
  content_type "text/plain"
end

get '/' do
  <<-EOT
curl -v -F data=@/etc/passwd #{BASE}/~paste | grep Location:
  EOT
end

post '/~paste' do
  if !params[:data] ||
     !(tmp = params[:data][:tempfile]) ||
     !tmp.respond_to?(:read)
    halt 422, "invalid data\n"
  end
  name = SecureRandom.urlsafe_base64(8)
  File.open(File.join(STORE, name), "w+") do |f|
    f.write(tmp.read)
  end
  redirect to("/#{name}")
end

get '/:name' do
  send_file File.join(STORE, params[:name])
end

run Sinatra::Application
