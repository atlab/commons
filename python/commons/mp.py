import datajoint as dj

schema = dj.schema('common_multipatch', locals())


@schema
class Cell(dj.Manual):
    definition = None


@schema
class CellAssignment(dj.Manual):
    definition = None


@schema
class CellPair(dj.Manual):
    definition = None


@schema
class Series(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Sketch(dj.Manual):
    definition = None
