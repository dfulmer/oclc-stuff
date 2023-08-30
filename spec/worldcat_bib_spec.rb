describe WorldcatBib do
  let(:tag_001){ "1354771677" }
  let(:tag_019_a){ "1329221766" }
  let(:tag_019_a2){ "9999999999" }

  before(:each) do
    @worldcat_bib = File.read("./spec/fixtures/worldcat_output.xml")
  end
  context ".for" do
    it "returns a WorldcatBib for a valid oclc_numb" do
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/#{tag_001}?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}").to_return(status: 200, body: @worldcat_bib, headers: {})

      expect(described_class.for(tag_001).class).to eq(WorldcatBib)
    end

    it "raises a StandardError if there's worldcat_bib" do
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/#{tag_001}?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}").to_return(status: 500, body: "", headers: {})
      expect { described_class.for(tag_001) }.to raise_error(StandardError)
    end
  end

  subject do
    described_class.new(@worldcat_bib)
  end

  context "#tag_019" do
    it "returns an array of 019 subfield values" do
      expect(subject.tag_019).to eq([tag_019_a, tag_019_a2])
    end
  end
  
  context "#match_any_019?" do
    it "is true if if array contains a match" do
      expect(subject.match_any_019?(["1234",tag_019_a])).to eq(true)
    end
    it "is false when array does not contain a match" do
      expect(subject.match_any_019?(["1234"])).to eq(false)
    end
  end
end
