# Opens file example.txt, in directory /in, and gets one mmsid and one OCLC number per line
# Suggestion: ruby oclc_cross_ref_process.rb example.txt output.txt

require_relative './lib/look_up_mmsid.rb'
require_relative './lib/any_OCLC_num_in_Alma_035.rb'
require_relative './lib/number_change.rb'
require_relative './lib/update_alma.rb'


output_file = ARGV[1]
input_file = ARGV[0]

linecount = 0
countandskipcount = 0

File.open("out/#{output_file}", 'w') do |out|
  File.open("in/#{input_file}", 'r').each_line do |line|
    line.chomp!
    linecount += 1

    mmsid, oclcnum = line.split(/\t/)
    mmsid.strip!
    oclcnum.strip!

    # Using Alma api, look up file MMSID
    # MMSID found?
    if MmsidExists.new(mmsid).mmsidexist == false
      # No > Report error
      out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\tMMSID Doesn't Exist\n"
      # And go to next line
      next
    else
      # puts "keep going"
    end

    # Any OCLC num in Alma 035?
    oclcnumbersfromalma = Anyoclcnuminalma.new(mmsid).anyoclc
    if oclcnumbersfromalma == 'No OCLC numbers'
      # Process $a into XML
      # puts "process $a into xml"
      updatealmaresult = Updatealma.new().updatenow(mmsid, oclcnum)
      # puts updatealmaresult
      out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\t#{updatealmaresult} with 035 $a only\n"
      # And go to next line
      next
    else
      # puts "keep going"
    end

    # Same as file OCLC num?
    # 'oclcnum' is the cross reference file OCLC number, 'oclcnumbersfromalma' is an array of the numbers from Alma
    # Is the OCLC number in the array of OCLC numbers? Returns true if match, false if no match.
    if oclcnumbersfromalma.include?([ "#{oclcnum}" ]) == true
      #count and skip
      out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\tCount and skip\n"
      countandskipcount += 1
      # And go to next line
      next
    else
      # puts "keep going"
    end

    # Number change? (019 in Worldcat)
    # I think: take the OCLC number from the cross reference file, 'oclcnum', submit it to the Worldcat API and see if there are any 019 fields with the OCLC number from Alma?
    # 'oclcnumbersfromalma' is an array of oclc numbers from Alma (but I think there will only be one actual number), 'oclcnum' is the file OCLC number
    numberchangeresult = Numberchange.new(oclcnumbersfromalma, oclcnum).inohonenine
    if numberchangeresult == false
      # Report error
      # puts "Report error: Number Change No"
      out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\tNumber Change No; Report error\n"
      # And go to next line
      next
    else
      # puts "keep going"
      # puts numberchangeresult
    end

    # Process $a and $z into xml
    # 'oclcnum' will be the $a, the $z(s) will be from the 'inohonenine' method: 'numberchangeresult'.
    updatealmaresult = Updatealma.new().updatenow(mmsid, oclcnum, numberchangeresult)
    #puts updatealmaresult

    # Add a line to the report with the updatealamresult.
    # puts "#{linecount}\t#{mmsid}\t#{oclcnum}\n"
    out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\t#{updatealmaresult} with 035 $a and $z(s)\n"
  end
end