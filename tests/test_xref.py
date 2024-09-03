from oclc_xrefs.xref import Xref

def test_initialize():
    xref = Xref(mms_id="99andothernumbers", oclc_num="oclcnumber")
    assert xref.mms_id == "99andothernumbers"
    assert xref.oclc_num == "oclcnumber"