#!/usr/bin/env python3
"""
This script processes oclc xrefs
"""

import sys
import argparse
from oclc_xrefs.xref import Xref
import logging



def main(argv=sys.argv[1:]):
    logging.basicConfig(
        level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
     )
    parser = argparse.ArgumentParser(description='Processes OCLC Xref File')
    parser.add_argument('input_file',help="path to input file of oclc xrefs")
    parser.add_argument('output_file_name',help="start of the name for the output files. This will create the files FILENAME_log.txt, FILENAME_report.txt, FILENAME_errors.txt")
    
    args = parser.parse_args(args=argv)


    counts = {
        "skipped": 0,
        "updates": 0,
        "add_a": 0,
        "update_a_and_z": 0,
        "errors": 0,
    }
    
    log =  open(f"{args.output_file_name}_log.txt", 'w', encoding="utf-8")
    error =  open(f"{args.output_file_name}_error.txt", 'w', encoding="utf-8")
    report =  open(f"{args.output_file_name}_report.txt", 'w', encoding="utf-8")
    
    logging.info(f"Start processing OCLC Xref File: {args.input_file}")

    with open(args.input_file) as f:
        for line in f:
            line = line.strip()
            parts = line.split("\t")
            mms_id = parts[0].strip()
            oclc_num = parts[1].strip()
            xref = Xref(mms_id=mms_id, oclc_num=oclc_num)
            result = xref.process()

            match result["kind"]:
                case "skip":
                    counts["skipped"] += 1
                case "error":
                    counts["errors"] +=1
                case "update_a":
                    counts["updates"] +=1
                    counts["add_a"] +=1
                case "update_a_and_z":
                    counts["updates"] +=1
                    counts["update_a_and_z"] +=1

            text = f"{mms_id}\t{oclc_num}\t{result['msg']}\n"             

            log.write(text)
            if result["kind"] == "error":
                error.write(text)
                logging.error(msg=text)
            else:
                logging.info(msg=text)
            
    for count in counts:
        report.write(f"{count}: {counts[count]}\n")

    log.close()
    report.close()
    error.close()

    logging.info(f"Finished processing OCLC Xref File: {args.input_file}")

    return 0 # ok status


if __name__=='__main__':
    sys.exit(main())

