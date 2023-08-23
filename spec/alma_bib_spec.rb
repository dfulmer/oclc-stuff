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

  context "updating the alma record" do
    #this is easier to test
    let(:generate_updated_bib) {subject.generate_updated_bib(new_oclc_number: "12345",numbers_from_019: ["555"]) }
    let(:update_035) {subject.update_035(new_oclc_number: "12345", numbers_from_019: ["555"]) }

    context "#generate_updated_bib" do
      it "has new OCLC number in the 035 a" do
        record = generate_updated_bib
        subfield_as_for_035 = record.fields("035").map{|x| x["a"]}
        #the one oclc is the one in the params
        expect(subfield_as_for_035.include?("(OCoLC)12345")).to eq(true)

        #only one oclc
        expect(subfield_as_for_035.find_all{|x| x.match?(/OCoLC/)}.count).to eq(1)


        #expect(subfields_for_035.find_all{|x| x.match?(/OCoLC/) }.count).to eq(1)
      end
      it "has the 019s in the subfield z" do
        record = generate_updated_bib
        subfield_zs_for_035 = record.fields("035").map{|x| x["z"]}.compact
        expect(subfield_zs_for_035.include?("(OCoLC)555")).to eq(true)
        expect(subfield_zs_for_035.find_all{|x| x.match?(/OCoLC/)}.count).to eq(1)
      end
    end
    context "#update_035" do
      before(:each) do
        @record = "<bib>" + generate_updated_bib.to_xml_string + "</bib>"
        @req = stub_request(:put, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?check_match=false&override_lock=true&override_warning=true&stale_version_check=false&validate=false").with(body: @record)
      end
      it "sends updated MARC XML bib record to the appropriate API endpoint" do
        update_035
        expect(@req).to have_been_requested
      end
      it "returns 'Record updated' when status is 200" do
        @req.to_return(status: 200)
        expect(update_035).to eq("Record updated")
      end
      it "returns 'Record not updated' when status is not 200" do
        @req.to_return(status: 500)
        expect(update_035).to eq("Record not updated")
      end
    end
  end
end
