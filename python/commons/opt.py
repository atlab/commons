import datajoint as dj

schema = dj.schema('common_optical', locals())


@schema
class LoomMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class SpotMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Structure(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class StructureMask(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Sync(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")
