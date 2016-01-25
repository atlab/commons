import datajoint as dj

schema = dj.schema('common_microcolumns', locals())


@schema
class Connections(dj.Manual):
    definition = None

@schema
class Distances(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")

@schema
class Experiments(dj.Manual):
    definition = None

@schema
class PatchCells(dj.Manual):
    definition = None

@schema
class PatchColumns(dj.Manual):
    definition = None

@schema
class QuantClones(dj.Manual):
    definition = None

@schema
class QuantExp(dj.Manual):
    definition = None

@schema
class Slices(dj.Manual):
    definition = None

