#!/usr/bin/env python3
"""
This script processes oclc xrefs
"""

import sys
import argparse
from oclc_xrefs.xref import Xref


def main(argv=sys.argv[1:]):
    parser = argparse.ArgumentParser(description='Processes OCLC Xref File')
    parser.add_argument('input_file',help="path to input file of oclc xrefs")
    parser.add_argument('--report_file', default="report.txt",
                        help="path to report file; default is report.txt")
    parser.add_argument('--error_file', default="error.txt",
                        help="path to error file; default is error.txt")
    
    args = parser.parse_args(args=argv)

    counts = {
        "skipped": 0,
        "updates": 0,
        "add_a": 0,
        "update_a_and_z": 0,
        "errors": 0,
    }
    report =  open(args.report_file, 'w', encoding="utf-8")
    error = open(args.error_file, 'w', encoding="utf-8")

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

            report.write(text)
            if result["kind"] == "error":
                error.write(text)
    report.write("\n\n\n")
    for count in counts:
        report.write(f"{count}: {counts[count]}\n")

    report.close()
    error.close()

    return 0 # ok status


if __name__=='__main__':
    sys.exit(main())

