require "faraday"
require "marc"
require "stringio"

# Number change? (019 in Worldcat)
# -No > Report Error
# -Yes > Process $a and $z into xml

# Given an MMS ID and OCLC number from the cross reference file,
# and an OCLC number from Alma 035 which is not the same as the OCLC number from the cross reference file,
# check to see if the OCLC number from Alma 035 is in the 019 of the Worldcat record with the OCLC number from the cross reference file.

# This one does have an Alma 035 which is in the 019 of the Worldcat record with the OCLC number from the cross reference file:
# Suggestion: ruby number_change.rb 99187695315506381 1291261371 1285697983

# This one will not work, i.e. the OCLC number from Alma is not in the 019 of the OCLC record (for Report error):
# Suggestion: ruby number_change.rb 99187695150106381 1035091437 123

# You need an MMS ID and two oclc numbers
if ARGV[0] !~ /\A\d+6381\z/ || ARGV[1].nil? || ARGV[2].nil?
  puts "Usage: ruby #{$0} [Number ending in ...6381], oclc number, oclc number"
  exit
end

wskey = ENV.fetch("WORLDCAT_API_KEY")

# Assign 'mmsid' to the MMS ID number submitted
mmsid = ARGV.shift

# Assign 'xrefoclc' to the OCLC number from the cross reference file
xrefoclc = ARGV.shift

# Assign 'almaoclc' to the OCLC number from Alma
almaoclc = ARGV.shift

# Connect to the Worldcat API
connection = Faraday.new(
)

# Retrieve the bib record with the MMS ID given
response = connection.get do |req|
  req.url "https://worldcat.org/webservices/catalog/content/#{xrefoclc}?servicelevel=full&wskey=#{wskey}"
  req.headers[:content_type] = 'application/json'
  req.headers[:Accept] = 'application/json'
end
#puts JSON.pretty_generate(JSON.parse(response2.body))
#puts response.body

# Just look for 019 field (which is not repeatable) and get the a subfields, however many there are.

# Using the marc gem, add an 035 field to the bib record that was retrieved from Alma, and store the new, edited bib record as a string in 'xmlrec'
reader = MARC::XMLReader.new(StringIO.new(response.body))

subfieldas = []
reader.each do |record|
  record.fields("019").each do |y|
    y.subfields.each do |z|
      subfieldas.push(z.value) 
    end
  end

#  puts record.fields("019")["a"].value.to_s
  #record.each_by_tag("019") {|field| ... }
end

# Is almaoclc in the array of subfieldas?
puts subfieldas.include?(almaoclc)
subfieldas.include?(almaoclc) ? (puts "The OCLC number from Alma 035 is in the 019 of the Worldcat record with the OCLC number from the cross reference file.") : (puts "Nope.")
