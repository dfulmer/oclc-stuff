describe OCLCProcessor do
  context ".process" do
    before(:each) do
      stub_request(:get, "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/99187608627106381?expand=None&view=full").
        with(
          headers: {
            'Accept'=>'application/json',
            'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization'=>"apikey #{ENV.fetch("ALMA_API_KEY")}",
            'Content-Type'=>'application/json',
            'User-Agent'=>'Faraday v2.7.4'
          }).
          to_return(status: 200, body: File.open("./spec/fixtures/alma_bib.json"), headers: {})
    end
    it "handles existing oclc number that matches alma oclc" do
      `cp ./spec/fixtures/input_example.txt ./in/input.test`
      OCLCProcessor.process("input.test","output.test")
      output = File.read("./out/output.test")
      expect(output).to include("Count and skip")
    end
    it "handles non match" do
      `cp ./spec/fixtures/input_example2.txt ./in/input.test`
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
      expect(output).to include("Number Change No; Report error")
    end
  end
  after(:each) do
    `rm ./in/input.test`
    `rm ./out/output.test`
  end

end
