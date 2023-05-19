require "faraday"
require "marc"
require "stringio"

# This one has a lot of oclc numbers: 99187448113806381

class Anyoclcnuminalma
  def initialize(mmsid)
    @mmsid = mmsid
  end

  def anyoclc
    apikey = ENV.fetch("ALMA_API_KEY")
    connection = Faraday.new(
    )
      
    response = connection.get do |req|
      req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{@mmsid}?view=full&expand=None"
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
      oclcnumbers
    else
      'No OCLC numbers'
    end
  end
end