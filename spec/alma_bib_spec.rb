describe AlmaBib do

  before(:each) do
    @alma_bib = JSON.load_file("./spec/fixtures/alma_bib.json")
  end

  context ".for" do
    it "returns an AlmaBib for a valid mmsid" do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full").to_return(status: 200, body: @alma_bib.to_json, headers: {})

      expect(described_class.for("99187608627106381").class).to eq(AlmaBib)
    end

    it "raises a StandardError if there's no mms_id" do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full").to_return(status: 500, body: "", headers: {})
      expect { described_class.for("99187608627106381") }.to raise_error(StandardError)
    end
  end

  subject do
    described_class.new(@alma_bib)
  end

  let (:a_oclc) { "1354771677" }

  let (:z_oclc) { "1329221766" }

  let(:remove_a) {
    @alma_bib["anies"].first.gsub!("(OCoLC)#{a_oclc}","(asdf)1234")
  }

  let(:remove_z){
    @alma_bib["anies"].first.gsub!("(OCoLC)#{z_oclc}","(asdf)1234")
  }

  context "#no_oclc?" do
    it "returns false when both a and z have oclc" do
      expect(subject.no_oclc?).to eq(false) 
    end
    
    it "is false when only z" do
      remove_a
      expect(subject.no_oclc?).to eq(false) 
    end

    it "is false when only a" do
      # remove z
      remove_z
      expect(subject.no_oclc?).to eq(false) 
    end

    it "is true when there aren't any a or z" do
      remove_a
      remove_z
      expect(subject.no_oclc?).to eq(true) 
    end
  end

  context "#oclc_a" do
    it "returns an array of the 035 $a values" do
      expect(subject.oclc_a).to eq([a_oclc])
    end
    it "is empty when there aren't any a's" do
      remove_a
      expect(subject.oclc_a).to eq([])
    end
  end

  context "#oclc_z" do
    it "returns an array of the 035 $z values" do
      expect(subject.oclc_z).to eq([z_oclc])
    end
    it "is empty when there aren't any z's" do
      remove_z
      expect(subject.oclc_z).to eq([])
    end
  end

  context "#oclc_all" do
    it "returns an array of all oclc values in the record" do
      expect(subject.oclc_all).to eq([a_oclc,z_oclc])
    end
    it "is empty when there aren't any a's or z's" do
      remove_a
      remove_z
      expect(subject.oclc_all).to eq([])
    end
  end

  context "#has_oclc?" do
    it "returns true if an a field is checked" do
      expect(subject.has_oclc?(a_oclc)).to eq(true)
    end
    it "returns true if a z field is checked" do
      expect(subject.has_oclc?(z_oclc)).to eq(true)
    end
    it "returns false if number doesn't match" do
      expect(subject.has_oclc?("1235")).to eq(false)
    end
  end
end
