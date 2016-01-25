import datajoint as dj

schema = dj.schema('common_two_photon', locals())


@schema
class Align(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class CaOpt(dj.Lookup):
    definition = None


@schema
class CellClass(dj.Lookup):
    definition = None


@schema
class CellClassification(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class CellFreqTuning(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class CellOriMap(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class CellSpeedTuning(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class CellXYZ(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Cos2Map(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Cos2MapOpto(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Extract(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Extract2(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class ExtractOpt(dj.Lookup):
    definition = None


@schema
class FineAlign(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class FineOriMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class FineVonMap(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class FrameMask(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class FreqMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Geometry(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Ministack(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class MinistackSegment(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")


@schema
class Motion3D(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class OriDesign(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class OriMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class OriMapOpto(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Segment(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class Segment3D(dj.Imported):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")
#

@schema
class SegmentManual(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class SegOpt(dj.Lookup):
    definition = None



@schema
class SpikeCorrMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Sync(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Trace(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Trace2(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")

#
# @schema
# class Trace3D(dj.Imported):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")


# @schema
# class TraceOri(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")
#

# @schema
# class TraceVon(dj.Computed):
#     definition = None
#
#     def _make_tuples(self, key):
#         raise NotImplementedError("This table is implemented from matlab.")
#

# @schema
# class VisualQuality(dj.Manual):
#     definition = None


@schema
class VonMap(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class VonTraceShuffle(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")
