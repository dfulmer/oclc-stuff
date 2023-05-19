# oclc-stuff
Experiments.

## Setting up OCLC stuff

Clone the repo

```
git clone git@github.com:dfulmer/oclc-stuff.git
cd oclc-stuff
```

copy .env-example to .env

```
cp .env-example .env
```

edit .env with actual environment variables

build container
```
docker-compose build
```

bundle install
```
docker-compose run --rm app bundle install
```

start container
```
docker-compose up -d
```

## Using Individual Programs

### Download cross reference file
open_file.rb
This script will open a file called 'example.txt' in the directory /in, print out the mmsid and oclc number line by line then print out those values in a file called 'output.txt' in the directory /out.
```
docker-compose run --rm app bundle exec ruby programs/open_file.rb example.txt output.txt
```

### Using Alma api, look up file MMSID==MMSID found?
lookup_mmsid.rb
This script will check for the existence of a record in Alma using an MMS ID supplied.
```
docker-compose run --rm app bundle exec ruby programs/lookup_mmsid.rb 99187695150106381
```

### Any OCLC num in Alma 035?
anyoclcnuminalma035.rb
This script will check an MMS ID in Alma to see if there are any OCLC numbers in it. Returns the list of OCLC numbers (just the number) from the 035 $a subfields only, or 'No OCLC numbers' if there are no 035s with OCoLC in them.
```
docker-compose run --rm app bundle exec ruby programs/anyoclcnuminalma035.rb 99187695150106381
```
### Same as file OCLC num?
same_as_file_oclc_num.rb
Compare a number to a list of numbers. Is the number in the list of numbers?
```
docker-compose run --rm app bundle exec ruby programs/same_as_file_oclc_num.rb 607677953 [607677953 ,607677953]
  => true
docker-compose run --rm app bundle exec ruby programs/same_as_file_oclc_num.rb 6076779534 [607677953, 607677953]
  => false
```

### Number change? (019 in Worldcat)
number_change.rb
Given an MMS ID and OCLC number from the cross reference file,
and an OCLC number from Alma 035 which is not the same as the OCLC number from the cross reference file,
check to see if the OCLC number from Alma 035 is in the 019 of the Worldcat record with the OCLC number from the cross reference file.
```
docker-compose run --rm app bundle exec ruby programs/number_change.rb 99187695315506381 1291261371 1285697983
  => Yes, number change.
docker-compose run --rm app bundle exec ruby programs/number_change.rb 99187695150106381 1035091437 123
  => Nope
```

### Process $a and $z into xml
update_alma.rb
Receive an MMS ID number followed by very specifically formatted 035 contents which will be added to the Alma record corresponding to the MMS ID.
This will also remove any existing 035 with "OCoLC" in it.
```
docker-compose run --rm app bundle exec ruby programs/update_alma.rb 99187695150106381 'subfielda=(New)12345'
  => Removes any OCoLC 035s on MMS ID 99187695150106381, and adds one new 035 with the supplied $a

docker-compose run --rm app bundle exec ruby programs/update_alma.rb 99187695150106381 'subfielda=(New)12345' 'subfieldz=(Old)54321'
  => Removes any OCoLC 035s on MMS ID 99187695150106381, and adds one new 035 with the supplied $a and $z

docker-compose run --rm app bundle exec ruby programs/update_alma.rb 99187695150106381 'subfielda=(New)12345' 'subfieldz=(Old)54321' 'subfieldz=(Old)9876'
  => Removes any OCoLC 035s on MMS ID 99187695150106381, and adds one new 035 with the supplied $a and two $z subfields
```

### Update Alma with file OCLC num
See above: update_alma.rb, which may be supplied with only one $a subfield.

### Report error
See above: open_file.rb, which writes to output.txt in the /out directory.

### Process $a into XML
See above: update_alma.rb


## Bringing it all together

### Flow for all OCLC cross references
oclc_cross_ref_process.rb
Opens file example.txt (or whatever file name you use when running the program), in directory /in, and gets one mmsid and one OCLC number per line.
Prints out one line in /out/output.txt per each line from /in/example.txt, with a note about what happened.
```
docker-compose run --rm app bundle exec ruby oclc_cross_ref_process.rb example.txt output.txt
  => look in out/output.txt for results.
```