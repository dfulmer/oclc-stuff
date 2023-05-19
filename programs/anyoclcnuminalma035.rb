require "faraday"
require "marc"
require "stringio"

# Suggestion: ruby anyoclcnuminalma035.rb 99187695150106381
# This one has a lot of oclc numbers: 99187448113806381

# You need an MMS ID
if ARGV[0] !~ /\A\d+\z/
  puts "Usage: ruby #{$0} [Number ...]"
  exit
end
mmsid = ARGV[0]
apikey = ENV.fetch("ALMA_API_KEY")
connection = Faraday.new(
)
  
response = connection.get do |req|
  req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}?view=full&expand=None"
  req.headers[:content_type] = 'application/json'
  req.headers[:Accept] = 'application/json'
  req.headers[:Authorization] = "apikey #{apikey}"
end
bibrecord = JSON.parse(response.body)['anies'].first
reader = MARC::XMLReader.new(StringIO.new(bibrecord))

oclcnumbers = []
reader.each do |record|
  # Retrieve all the OCLC numbers
  record.each_by_tag("035") do |field|
    field.subfields.each do |sub|
      if sub.code == "a"
        if sub.value.match?(/OCoLC/)
          oclcnumbers.push(sub.value.scan(/\d+/))
        end
      end
    end
  end
end

if oclcnumbers.length > 0
   puts oclcnumbers
else
  puts 'No OCLC numbers'
end