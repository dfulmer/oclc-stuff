from oclc_xrefs.alma_bib import AlmaBib
from oclc_xrefs.worldcat_bib import WorldcatBib
from functools import cached_property


class Xref:
    def __init__(self, mms_id, oclc_num, alma_bib=None, worldcat_bib=None):
        self.mms_id = mms_id
        self.oclc_num = oclc_num
        self._alma_bib = alma_bib
        self._worldcat_bib = worldcat_bib

    @property
    def mms_id_is_in_alma(self):
        return self.alma_bib.is_in_alma
    
    @property
    def alma_oclc_nums(self):
        return self.alma_bib.oclc

    @property
    def alma_035a_matches_xref(self):
        if self.oclc_num in self.alma_oclc_nums:
          return True
        else:
          return False
    
    @property
    def matches_any_worldcat_019(self):
        if self.worldcat_bib.has_any_019(self.alma_oclc_nums):
            return True
        else:
            return False
    
    def process(self):
        try:
            self.alma_bib
        except:
           return { 
               "kind": "error", 
               "msg": "ERROR: Can't open Alma bib record"
            }
        if not self.mms_id_is_in_alma:
            return { "kind": "error", "msg": "ERROR: MMS_ID not found" }
        try: 
          self.alma_oclc_nums 
        except:
           return { 
               "kind": "error", 
               "msg": "ERROR: Invalid oclc number(s) in Alma"
            }
        if not self.alma_oclc_nums:
            try:
                self.alma_bib.update_035a(new_oclc_number=self.oclc_num)
            except:
                return { 
                    "kind": "error", 
                    "msg": "ERROR: update alma with 035 $a failed"
                    }
            return { "kind": "update_a", "msg": "UPDATE: 035 $a"}
        elif self.alma_035a_matches_xref:
            return {"kind": "skip", "msg": "SKIP"} 
        elif self.matches_any_worldcat_019:
            try:
                self.alma_bib.update_035a(
                    new_oclc_number=self.oclc_num,
                    numbers_from_019=self.worldcat_bib.tag_019
                    )
            except:
                return { 
                    "kind": "error", 
                    "msg": "ERROR: update alma with 035 $a and $z failed"
                    }
            return { "kind": "update_a_and_z", "msg": "UPDATE: 035 $a and $z"}
        else:
            return { "kind": "error", "msg": "ERROR: No number change found"}
            
            





    @cached_property
    def alma_bib(self):
        if not self._alma_bib:
            self._alma_bib = AlmaBib.fetch(self.mms_id)
        return self._alma_bib

    @cached_property
    def worldcat_bib(self):
        if not self._worldcat_bib:
            self._worldcat_bib = WorldcatBib.fetch(self.oclc_num)
        return self._worldcat_bib