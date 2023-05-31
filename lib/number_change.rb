require "faraday"
require "marc"
require "stringio"

# Number change? (019 in Worldcat)
# -No > Report Error
# -Yes > Process $a and $z into xml

# Given an OCLC number from the cross reference file,
# and an OCLC number from Alma 035 which is not the same as the OCLC number from the cross reference file,
# check to see if the OCLC number from the Alma 035 is in the 019 of the Worldcat record with the OCLC number from the cross reference file.

class Numberchange
  def initialize(almaoclcarray, fileoclc)
    @almaoclcnumber = almaoclcarray.shift
    @fileoclc = fileoclc
  end

  def in_019?
    # The Alma OCLC number must be a string
    subfield_as.include?(@almaoclcnumber.to_s)
  end

  def subfield_as
    reader = MARC::XMLReader.new(StringIO.new(oclc_response.body))

    list = []
    reader.each do |record|
      record.fields("019").each do |y|
        y.subfields.each do |z|
          list.push(z.value)
        end
      end

      # puts record.fields("019")["a"].value.to_s
      # record.each_by_tag("019") {|field| ... }
    end
    list
  end
  def inohonenine
    # puts JSON.pretty_generate(JSON.parse(response2.body))
    # puts response.body

    # Just look for 019 field (which is not repeatable) and get the a subfields, however many there are.
    #
    # Is almaoclc in the array of subfield_as?
    # puts subfieldas.include?(newalma)
    # subfieldas.include?(newalma) ? (puts "The OCLC number from Alma 035 is in the 019 of the Worldcat record denoted by the OCLC number from the cross reference file.") : (puts "Nope.")
    in_019? ? (subfield_as) : (false)
  end
  def oclc_response 
      wskey = ENV.fetch("WORLDCAT_API_KEY")

      # Connect to the Worldcat API
      connection = Faraday.new

      # Retrieve the OCLC record with the cross reference file OCLC number given
      @oclc_response ||=  connection.get do |req|
        req.url "https://worldcat.org/webservices/catalog/content/#{@fileoclc}?servicelevel=full&wskey=#{wskey}"
        req.headers[:content_type] = "application/json"
        req.headers[:Accept] = "application/json"
      end
  end
end
