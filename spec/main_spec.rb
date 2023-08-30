describe OCLCProcessor do
  context ".process" do
    let(:base_alma) {
      # this file has
      # mmid: 99187608627106381
      # 035 $a (OCoLC)1354771677
      # 035 $z (OCoLC)1329221766
      File.read("./spec/fixtures/alma_bib.json")
    }

    let(:base_worldcat) {
      # this file has:
      # 001: 1354771677
      # 019: 1329221766
      File.read("./spec/fixtures/worldcat_output.xml")
    }

    let(:output) { File.read("./out/output.test") }

    def stub_alma_request(status: 200, body: base_alma)
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full").to_return(status: status, body: body, headers: {})
    end

    it "handles mmsid that doesn't exist" do
      stub_alma_request(status: 400)
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test", "output.test")
      expect(output).to include("MMSID Doesn't Exist")
    end

    it "updates alma with xref oclc number when there's no oclc for the alma id" do
      body = base_alma.gsub(/\(OCoLC\)\d+/, "")
      stub_alma_request(body: body)
      stub_request(:put, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?validate=false&override_warning=true&override_lock=true&stale_version_check=false&check_match=false")
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test", "output.test")
      expect(output).to include("Record updated with 035 $a only")
    end
    it "handles xref oclc number that matches alma oclc 035a" do
      stub_alma_request
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test", "output.test")
      expect(output).to include("Count and skip")
    end
    it "handles when alma has oclc numbers that don't match what was given in the xref file, and worldcat's record for the xref doesn't have an 019 that matches any of the alma oclc" do
      stub_alma_request
      worldcat_output = base_worldcat.gsub("1354771677", "999").gsub("1329221766", "999")
      `cp ./spec/fixtures/input_non_match.txt ./in/input.test`
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/9999999999?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}")
        .to_return(status: 200, body: worldcat_output, headers: {})
      OCLCProcessor.process("input.test", "output.test")
      expect(output).to include("Number Change No; Report error")
    end
    it "handles when alma has oclc number that doesn't match what was in the xref file, it's a matches something in z" do
      # These are in base_alma
      # 035 $a (OCoLC)1354771677
      # 035 $z (OCoLC)1329221766

      # This alma bib should have an oclc number that doesn't match whats in the
      # xref but will be in the z of the xref
      alma_bib = base_alma.gsub("1354771677", "1329221766")
      stub_alma_request(body: alma_bib)
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/1354771677?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}")
        .to_return(status: 200, body: base_worldcat, headers: {})
      stub_request(:put, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?check_match=false&override_lock=true&override_warning=true&stale_version_check=false&validate=false")
      OCLCProcessor.process("input.test", "output.test")
      expect(output).to include("Record updated with 035 $a and $z(s)")
    end
  end
  after(:each) do
    `rm ./in/input.test`
    `rm ./out/output.test`
  end
end
