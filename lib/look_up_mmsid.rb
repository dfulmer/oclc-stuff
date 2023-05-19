require "faraday"

class MmsidExists
  def initialize(mmsid) 
    @mmsid = mmsid 
 end 
 
 def mmsidexist
  apikey = ENV.fetch("ALMA_API_KEY")

  connection = Faraday.new(
  )
  
  response = connection.get do |req|
    req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{@mmsid}?view=full&expand=None"
    req.headers[:content_type] = 'application/json'
    req.headers[:Accept] = 'application/json'
    req.headers[:Authorization] = "apikey #{apikey}"
  end
  
  #puts response.status #200 means it exists, anything else means it does not exist
  #puts response.body
  #puts JSON.pretty_generate(JSON.parse(response.body))
  #response.status != 200 ? (puts "true") : (puts "false")
  
  if response.status == 200
    true
  else
    false
  end
 end
end

# test = MmsidExists.new('99187695150106381')
# test.mmsidexist