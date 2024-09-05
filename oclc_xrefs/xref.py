from oclc_xrefs.alma_bib import AlmaBib
from functools import cached_property


class Xref:
    def __init__(self, mms_id, oclc_num):
        self.mms_id = mms_id
        self.oclc_num = oclc_num
        self._alma_bib = None

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
    
    @cached_property
    def alma_bib(self):
        self._alma_bib = AlmaBib.fetch(self.mms_id)
        return self._alma_bib
