require "faraday"
require "marc"
require "stringio"

class Updatealma
  def initialize() 
  end 
 
  def updatenow(mmsid, oclcnum, *incomingzs)

  # puts mmsid
  # puts "subfielda=(OCoLC)#{oclcnum}"
  # formatteda = "subfielda=(OCoLC)#{oclcnum}"
  # incomingzs.each { |a| puts "subfieldz=(OCoLC)#{a}" }

  formattedzs = []
  incomingzs.each do |b|
    # puts "subfieldz=(OCoLC)#{b}"
    b.each do |c|
      # puts "subfieldz=(OCoLC)#{c}"
      formattedzs.push("subfieldz=(OCoLC)#{c}")
     end
  end

  # Objective here is to receive an MMS ID number followed by
  # OCLC number from cross reference file and then optionally
  # one or more subfield z(s) from the Worldcate record 019.
  # This will also remove any existing 035 with "OCoLC" in it.

  # mmsid = "99187695150106381"
  # contentsof035 = "(New)035a 2023-05-09-2"
  apikey = ENV.fetch("ALMA_API_KEY")

  # Retrieve a bib record from Alma by MMS ID,
  # add the 035 field(s), and update the Alma bib record.
  # Connect to the Alma API
  connection = Faraday.new(
  )

  # Retrieve the bib record with the MMS ID given
  response = connection.get do |req|
    req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}?view=full&expand=None"
    req.headers[:content_type] = 'application/json'
    req.headers[:Accept] = 'application/json'
    req.headers[:Authorization] = "apikey #{apikey}"
  end
  # Store the bib record as retrieved from Alma in 'bibrecord'
  bibrecord = JSON.parse(response.body)['anies'].first

  # Print out the bib record
  # puts "from alma"
  # puts bibrecord
  # puts " "

  # Using the marc gem, add an 035 field to the bib record that was retrieved from Alma, and store the new, edited bib record as a string in 'xmlrec'
  reader = MARC::XMLReader.new(StringIO.new(bibrecord))

  xmlrec = ""
  reader.each do |record|
    ## This code will delete OCoLC 035 subfields:
    subfieldstodelete = []
    record.each_by_tag("035") do |field|
      if field.value.match?(/OCoLC/)
        subfieldstodelete.push(field)
      end
    end
    # puts subfieldstodelete
    
    subfieldstodelete.each do |deleteme|
      record.fields.delete(deleteme)
    end
    ##

    # Create a new 035 field
    newfield = MARC::DataField.new( '035', ' ', ' ')

    # Add the a subfield and add the (OCoLC) MARC Organization code in parentheses. Do not enter a space between the code and the control number.
    newfield.append(MARC::Subfield.new("a", "(OCoLC)#{oclcnum}"))

    # Retrieve the z subfields, and append them to the new 035 field
    formattedzs.each do |subfields|
      # Using a regular expression, create variable 'letter' for the subfield code and 'sub' for the subfield contents
      /subfield(?<letter>\w)=(?<sub>.*)/ =~ subfields
      # Append each subfield with contents to the new 035 field
      newfield.append(MARC::Subfield.new("#{letter}", "#{sub}"))
    end

    # Append the new 035 field to the record that had been retrieved from Alma
    record.append(newfield)

    # Make xmlrec a string version of the new, complete, bib record
    xmlrec = record.to_xml_string
  end

  # Print out the new, edited bib record, 'xmlrec'
  # puts "from rubymarcgem"
  # puts xmlrec
  # puts " "

  # Edit xmlrec to add a 'bib' root element, required for sending to the Alma API
  xmlrec = "<bib>" + xmlrec + "</bib>"

  # Send the edited record in to the Alma API to complete the update
  response2 = connection.put do |req|
    req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mmsid}?validate=false&override_warning=true&override_lock=true&stale_version_check=false&check_match=false"
    req.headers[:content_type] = 'application/xml'
    req.headers[:Accept] = 'application/json'
    req.headers[:Authorization] = "apikey #{apikey}"
    req.body = xmlrec
  end

  # Print out the response
  # puts " "
  # puts JSON.pretty_generate(JSON.parse(response2.body))

  # Or print out just the new, edited record
  # puts "from alma after update"
  # puts JSON.parse(response2.body)['anies'].first

  # Did it work?
  # response2.status == 200 ? (puts "Record updated") : (puts "Record not updated")
  response2.status == 200 ? "Record updated" : "Record not updated"
 end
end