# Open file example.txt, in directory /in and get an mmsid and an OCLC number
# Write to file output.txt in directory /out
# Suggestion: ruby open_file.rb example.txt output.txt

output_file = ARGV[1]
input_file = ARGV[0]

linecount = 0

File.open("out/#{output_file}", 'w') do |out|
  File.open("in/#{input_file}", 'r').each_line do |line|
    line.chomp!
    linecount += 1

    mmsid, oclcnum = line.split(/\t/)
    mmsid.strip!
    oclcnum.strip!

    puts mmsid
    puts oclcnum
    out.print "#{linecount}\t#{mmsid}\t#{oclcnum}\n"
  end
end