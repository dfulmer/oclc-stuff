class AlmaBib

  # Fetches a bib from Alma API. returns an Alma Bib object.
  #
  #@param mms_id [String] parsed json from Alma response
  #@return [AlmaBib] object wrapper of the Alma response
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

  #@param bib [Hash] parsed json from Alma response
  def initialize(bib)
    @bib = bib
  end

  def record
   for rec in MARC::XMLReader.new(StringIO.new(@bib["anies"].first))
  #@return [Array] list of values in the 035 $a
     return rec
   end
  end

  #@param control_number [String] OCLC control number 
  def has_oclc?(control_number)
    oclc_all.include?(control_number)
  end

  def no_oclc?
    oclc_all.empty?
  end

  def oclc_a
    oclc_subfield("a")
  end

  #@return [Array] list of values in the 035 $z
  def oclc_z
    oclc_subfield("z")
  end
 
  #@return [Array] list of values in the 035 $a and $z
  def oclc_all
    oclc_a + oclc_z
  end

  #@param subfield [String] 035 subfield to get OCLC strings friom  
  #@return [Array] Array of valid OCLC strings with the prefix stripped
  def oclc_subfield(subfield)
    subfields = record
      .fields("035")
      .map{|x| x.find_all {|s| s.code == subfield } }
      .flatten
      .map{|x| x.value }
    normalize_and_filter_oclc(subfields)
  end

  #@param subfields [Array] Array of values from the 035 subfields
  #@return [Array] Array of only valid OCLC strings with just the number
  def normalize_and_filter_oclc(subfields)
    subfields.filter_map do |s|
      if s.match?('OCoLC')
        # get only the digits"
        s.scan(/\d+/).first
      end
    end
  end
  
end
