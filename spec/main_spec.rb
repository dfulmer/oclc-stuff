describe OCLCProcessor do
  context ".process" do
    def stub_alma_request(status: 200, body: File.read("./spec/fixtures/alma_bib.json"))
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full").
          to_return(status: status, body: body, headers: {})
    end
    it "handles mmsid that doesn't exist" do
      stub_alma_request(status: 400)
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
          expect(output).to include("MMSID Doesn't Exist")
    end
    it "updates alma when there's no oclc for the alma id" do
      body = File.read("./spec/fixtures/alma_bib.json")
      body.gsub!(/\(OCoLC\)\d+/,"")
      stub_alma_request(body: body)
      stub_request(:put, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?validate=false&override_warning=true&override_lock=true&stale_version_check=false&check_match=false")
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
      expect(output).to include("with 035 $a only")
    end
    it "handles existing oclc number that matches alma oclc" do
      stub_alma_request
      `cp ./spec/fixtures/input_matches_a.txt ./in/input.test`
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
      expect(output).to include("Count and skip")
    end
    it "handles non match" do
      stub_alma_request
      `cp ./spec/fixtures/input_non_match.txt ./in/input.test`
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/9999999999?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}").
         with(                                                                                           
           headers: {                                                                                    
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',                                                            
          'User-Agent'=>'Faraday v2.7.4'
           }).
           to_return(status: 200, body: File.read("./spec/fixtures/worldcat_output.xml"), headers: {})
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
      expect(output).to include("Number Change No; Report error")
    end
    it "handles matching z" do
      stub_alma_request
      `cp ./spec/fixtures/input_matches_z.txt ./in/input.test`
      stub_request(:get, "https://worldcat.org/webservices/catalog/content/1329221766?servicelevel=full&wskey=#{ENV.fetch("WORLDCAT_API_KEY")}").
         with(                                                                                           
           headers: {                                                                                    
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',                                                            
          'User-Agent'=>'Faraday v2.7.4'
           }).
           to_return(status: 200, body: File.read("./spec/fixtures/worldcat_output.xml"), headers: {})
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
      expect(output).to include("with 035 $a and $z(s)")
    end 
  end
  after(:each) do
    `rm ./in/input.test`
    `rm ./out/output.test`
  end

end
