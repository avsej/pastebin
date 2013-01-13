require 'rubygems'
require 'securerandom'
require 'fileutils'
require 'bundler'
Bundler.require

BASE = "http://paste.avsej.net"
AWS.config('access_key_id' => ENV['AWS_ACCESS_KEY'],
           'secret_access_key' => ENV['AWS_SECRET_KEY'])

BUCKET = AWS::S3.new.buckets.create("files.avsej.net")

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

post '/~paste' do
  if !params[:data] ||
     !(tmp = params[:data][:tempfile]) ||
     !tmp.respond_to?(:read)
    halt 422, "invalid data\n"
  end
  name = SecureRandom.urlsafe_base64(8)
  object = BUCKET.objects["paste/#{name}"]
  object.write(:file => tmp.path,
               :reduced_redundancy => true,
               :acl => :public_read,
               :content_type => 'text/plain')
  redirect to("http://files.avsej.net/paste/#{name}")
end

get '/*' do
  <<-EOT
curl -v -F data=@/etc/passwd #{BASE}/~paste 2>&1 | grep Location:
  EOT
end

run Sinatra::Application
