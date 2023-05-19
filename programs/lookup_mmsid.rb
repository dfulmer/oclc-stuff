require "faraday"
# Using Alma api, look up file MMSID
# Puts 'MMS ID exists' if it does exist; puts 'MMS ID does not exist' if it does not exist.
# Suggestion: ruby lookup_mmsid.rb 99187695150106381

# You need an MMS ID
if ARGV[0] !~ /\A\d+\z/
  puts "Usage: ruby #{$0} [Number ...]"
  exit
end
mmsid = ARGV[0]
apikey = ENV.fetch("ALMA_API_KEY")
# mmsid = "99187695150106381" #test record
# mmsid = "89187695150106381" #no record
# mmsid = "99187695315706381" #a record I deleted; provides response.status=400

connection = Faraday.new(
)

response = connection.get do |req|
  req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}?view=full&expand=None"
  req.headers[:content_type] = 'application/json'
  req.headers[:Accept] = 'application/json'
  req.headers[:Authorization] = "apikey #{apikey}"
end

#puts response.status #200 means it exists, anything else means it does not exist
#puts response.body
#puts JSON.pretty_generate(JSON.parse(response.body))
#response.status != 200 ? (puts "true") : (puts "false")

if response.status == 200
  puts 'MMS ID exists'
else
  puts 'MMS ID does not exist'
end