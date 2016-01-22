import datajoint as dj

schema = dj.schema('dimitri_brain_state', locals())


@schema
class BrainState(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is populated from matlab.")


# @schema
# class TrialBrainState(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is populated from matlab.")


@schema
class TuningCondition(dj.Lookup):
    definition = None


# @schema
# class VonMises(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is populated from matlab.")

#
# @schema
# class VonMisesSet(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is populated from matlab.")
