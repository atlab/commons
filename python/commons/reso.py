import datajoint as dj

schema = dj.schema('common_resonant', locals())


@schema
class Align(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class AxonEffect(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class AxonMask(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Axons(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Bead(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class BeadStack(dj.Manual):
    definition = None


@schema
class CaOpt(dj.Lookup):
    definition = None


@schema
class ConditionMap(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Conditions(dj.Lookup):
    definition = None


@schema
class Cos2Map(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Effect(dj.Lookup):
    definition = None


@schema
class EphysTime(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Indicator(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class IndicatorSet(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class ManualSegment(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class ManualSegmentGlia(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class MiniStack(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Motion3D(dj.Imported):
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
class ScanInfo(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Segment(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class SegmentGlia(dj.Imported):
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
class TraceGlia(dj.Imported):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class TraceVonMises(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class Trial(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class TrialSet(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class TrialTrace(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class TrialTraceSet(dj.Computed):
    definition = None

    def _make_tuples(self, key):
        raise NotImplementedError("This table is implemented from matlab.")


@schema
class VolumeSlice(dj.Lookup):
    definition = None
