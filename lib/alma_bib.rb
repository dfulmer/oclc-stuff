class AlmaBib
  # Fetches a bib from Alma API. returns an Alma Bib object.
  #
  # @param mms_id [String] parsed json from Alma response
  # @return [AlmaBib] object wrapper of the Alma response
  def self.for(mms_id)
    apikey = ENV.fetch("ALMA_API_KEY")

    connection = Faraday.new

    response = connection.get do |req|
      req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{mms_id}?view=full&expand=None"
      req.headers[:content_type] = "application/json"
      req.headers[:Accept] = "application/json"
      req.headers[:Authorization] = "apikey #{apikey}"
    end

    # raising error because this really shouldn't happen.
    raise StandardError, "Failed to fetch bib from Alma" if response.status != 200

    AlmaBib.new(JSON.parse(response.body))
  end

  # @param bib [Hash] parsed json from Alma response
  def initialize(bib)
    @bib = bib
  end

  # Transforms the MarcXML string in the api response into a MARC::Record Object
  #
  # @return MARC::Record
  def record
    for rec in MARC::XMLReader.new(::StringIO.new(@bib["anies"].first))
      return rec
    end
  end

  # Does the 035 have this control number?
  #
  # @param control_number [String] OCLC control number
  # @return [Boolean]
  def has_oclc?(control_number)
    oclc_all.include?(control_number)
  end

  # Are there any OCLC numbers in the 035?
  #
  # @return [Boolean]
  def no_oclc?
    oclc_all.empty?
  end

  # @return [Array] list of values in the 035 $a
  def oclc_a
    oclc_subfield("a")
  end

  # @return [Array] list of values in the 035 $a
  def oclc_all
    oclc_a
  end

  # @param subfield [String] 035 subfield to get OCLC strings friom
  # @return [Array] Array of valid OCLC strings with the prefix stripped
  def oclc_subfield(subfield)
    subfields = record
      .fields("035")
      .map { |x| x.find_all { |s| s.code == subfield } }
      .flatten
      .map { |x| x.value }
    normalize_and_filter_oclc(subfields)
  end

  # This generates a MARC::Record object that has the 035 $a from the xref file,
  # and 035 $z from the 019 field from the Worldcat API.
  #
  # @param new_oclc_number [String] OCLC xref number
  # @param numbers_from_019 [Array] Array of old OCLC numbers from the 019
  # @return [MARC::Record] Altered MARC record associated with this alma bib
  def generate_updated_bib(new_oclc_number:, numbers_from_019:)
    
    # get a copy of the record to alter
    my_record = record
    my_record.fields("035").each do |field|
      if field.value.match?(/OCoLC/)
        my_record.fields.delete(field)
      end
    end

    # Create a new 035 field
    newfield = MARC::DataField.new("035", " ", " ")

    # Add the a subfield and add the (OCoLC) MARC Organization code in parentheses. Do not enter a space between the code and the control number.
    newfield.append(MARC::Subfield.new("a", "(OCoLC)#{new_oclc_number}"))

    numbers_from_019.each do |num|
      newfield.append(MARC::Subfield.new("z", "(OCoLC)#{num}"))
    end

    my_record.append(newfield)
    my_record
  end

  # Updates the alma record via the Alma API with the new oclc number from the
  # crossreference file and the oclc numbers from the 019. The new oclc number
  # goes into 035 $a the 019 oclc numbers go into 035 $z.
  #
  # This method calls the #generate_updated_bib method.
  #
  # @param new_oclc_number [String] OCLC xref number
  # @param numbers_from_019 [Array] Array of old OCLC numbers from the 019
  def update_035(new_oclc_number:, numbers_from_019: [])
    xml_record = "<bib>" +
      generate_updated_bib(
        new_oclc_number: new_oclc_number,
        numbers_from_019: numbers_from_019
      ).to_xml_string +
      "</bib>"

    response = Faraday.new.put do |req|
      req.url "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{@bib["mms_id"]}?validate=false&override_warning=true&override_lock=true&stale_version_check=false&check_match=false"
      req.headers[:content_type] = "application/xml"
      req.headers[:Accept] = "application/json"
      req.headers[:Authorization] = "apikey #{ENV.fetch("ALMA_API_KEY")}"
      req.body = xml_record
    end

    (response.status == 200) ? "Record updated" : "Record not updated"
  end

  # This is an effectively private method that takes an array of 035 subfields
  # gets only the OCLC numbers, and strips the non-numeric prefix.
  #
  # @param subfields [Array] Array of values from the 035 subfields
  # @return [Array] Array of only valid OCLC strings with just the number
  def normalize_and_filter_oclc(subfields)
    subfields.filter_map do |s|
      if s.match?("OCoLC")
        # get only the digits"
        #s.scan(/\d+/).first
        t = s.scan(/\d+/).first
        t.sub(/^[0]+/,'')
      end
    end
  end
end
