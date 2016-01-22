import datajoint as dj

schema = dj.schema('common_psy', locals())


@schema
class Condition(dj.Manual):
    definition = None


@schema
class DotMap(dj.Manual):
    definition = None


@schema
class FlashingBar(dj.Manual):
    definition = None


@schema
class Grating(dj.Manual):
    definition = None


@schema
class Looming(dj.Manual):
    definition = None


@schema
class MovingBar(dj.Manual):
    definition = None


@schema
class MovingNoise(dj.Manual):
    definition = None


@schema
class MovingNoiseLookup(dj.Lookup):
    definition = None


@schema
class NaturalMovie(dj.Manual):
    definition = None


@schema
class NoiseMap(dj.Manual):
    definition = None


@schema
class NoiseMapLookup(dj.Lookup):
    definition = None


@schema
class Session(dj.Lookup):
    definition = None


# @schema
# class VanGoghLookup(dj.Lookup):
#     definition = None


# @schema
# class Trial(dj.Manual):
#     definition = None


# @schema
# class Trippy(dj.Manual):
#     definition = None
#

# @schema
# class VanGogh(dj.Manual):
#     definition = None
