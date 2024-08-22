require "byebug"
class WorldcatBib
  attr_reader :bib
  def self.for(oclc_num)
    # wskey = ENV.fetch("WORLDCAT_API_KEY")

    # # Connect to the Worldcat API
    # connection = Faraday.new

    # # Retrieve the OCLC record with the cross reference file OCLC number given
    # response = connection.get do |req|
    #   req.url "https://worldcat.org/webservices/catalog/content/#{oclc_num}?servicelevel=full&wskey=#{wskey}"
    # end

    # # raising error because this really shouldn't happen.
    # raise StandardError, "Failed to fetch bib from Worldcat" if response.status != 200

    # WorldcatBib.new(response.body)
    # Here is the new stuff for dealing with the WorldCat Metadata API version 2.0
    result = `python3 lib/worldcatapiv2.py #{oclc_num}`

    # raising error because this really shouldn't happen.
    raise StandardError, "Failed to fetch bib from Worldcat" if result == "Error\n"

    WorldcatBib.new(result)
  end

  # @param bib [String] Marc xml string from Worldcat API
  def initialize(bib)
    for rec in MARC::XMLReader.new(StringIO.new(bib))
      @bib = rec
    end
  end

  # @return [Array] Array of all subfield values in 019
  def tag_019
    @bib.fields("019")&.first&.subfields&.filter_map do |subfield|
      subfield.value if subfield.code == "a"
    end || []
  end

  # Checks if any numbers in the list match anything in the 019
  #
  # @param array [Array] Array of oclc numbers
  # @return [Boolean]
  def match_any_019?(array)
    array.any? do |alma_oclc|
      tag_019.any? do |worldcat_oclc|
        alma_oclc == worldcat_oclc
      end
    end
  end
end
