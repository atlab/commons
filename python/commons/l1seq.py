import datajoint as dj

schema = dj.schema('cathryn_l1seq', locals())


@schema
class Experiments(dj.Manual):
    definition = None


@schema
class Cells(dj.Manual):
    definition = None
