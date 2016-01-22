import datajoint as dj

schema = dj.schema('dimitri_pupil', locals())


@schema
class BinnedNoiseCorr(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class Cos2Map(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")
#

@schema
class EpochR2(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class EpochTrial(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class EpochTrialSet(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class EpochVonMises(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class EpochVonMisesSet(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Intervals(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class OriDesign(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")

#
# @schema
# class OriMap(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")
#

@schema
class Phases(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class TrialNoiseCorr(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class CaOpt(dj.Lookup):
#     definition = None
#

@schema
class EpochOpt(dj.Lookup):
    definition = None
