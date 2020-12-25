require "json"
require "http/client"

class Repo
  include JSON::Serializable

  property full_name : String
  property private : Bool
  property languages_url : String
end

result = {} of String => Int32  

config = File.open("config.json") do |file|
  JSON.parse(file)
end

username = config["username"]
token = config["token"]
output_file = config["output_file"]

API_HOST = "https://api.github.com"
token_str = "token #{token}"

http = HTTP::Client.new(URI.parse(API_HOST))

http.tls?
resp = http.get("/users/#{username}/repos", headers: HTTP::Headers{"Authorization" => token_str})

repos = Array(Repo).from_json(resp.body)

repos.each do |repo|
  puts repo.full_name
  puts "---"
  if repo.private == false
    languages_uri = repo.languages_url.gsub(API_HOST, "")
    resp = http.get(languages_uri, headers: HTTP::Headers{"Authorization" => token_str})
    
    lang_hash = Hash(String, Int32).from_json(resp.body)
    lang_hash.each do |key1, value1|
      if !result[key1]?
        result[key1] = value1 
      end
      
      result.each do |key2, value2|
        if key1 == key2 
          result[key1] = value1 + value2
        end
      end
    end
  end
end

result = result.to_a.sort_by! { |key, value| value }.reverse.to_h
File.write("#{output_file}", result.to_pretty_json())
