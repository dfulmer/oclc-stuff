# Given an OCLC number, does it match one of the OCLC numbers in the supplied list?

# Suggestion: ruby same_as_file_oclc_num.rb 607677953 [607677953 ,607677953] == true
# Suggestion: ruby same_as_file_oclc_num.rb 6076779534 [607677953, 607677953] == false

# You need an OCLC number and a list of OCLC numbers
if ARGV[0] !~ /\A\d+\z/ || ARGV[1].nil?
  puts "Usage: ruby #{$0} oclc number, oclc numbers"
  exit
end

# Is the OCLC number in the array of OCLC numbers? Returns true if match, false if no match.
puts ARGV[1].include?(ARGV[0])