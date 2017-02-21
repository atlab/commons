import datajoint as dj
from commons import virus, mice

schema = dj.schema('common_injections', locals())


@schema
class Site(dj.Lookup):
    definition = """
    # Injection target site

    injection_site               : char(8) # ID
    ---
    """

    @property
    def contents(self):
        yield from zip(['V1', 'dLGN', 'AL', 'LM', 'S1','S2','M1', 'PM','_Test'])


@schema
class AtlasStereotacticTargets(dj.Lookup):
    definition = """
    # Unadjusted stereotactic coordinates from the mouse brain atlas

    ->Site
    target_id                     : char(20) # ID for this set of coordinates
    ---
    caudal                        : double # coordinate caudal from bregma in mm
    lateral                       : double # lateral coordinate in mm
    ventral                       : double # coordinate ventral from cortical surface in mm
    lambda_bregma_basedist=4.21   : double # base distance between lambda and bregma from the stereotactic atlas in mm
    """
    contents = [
                ('dLGN', 'Tang2016', 2.6, 2.15, 2.7, 4.21),
                ('dLGN', 'jake', 3.6, 2.15, 2.7, 4.21),
                ('dLGN', 'fabee01', 2.3, 2.25, 2.5, 4.21),  # dLGN
                ('dLGN', 'fabee05', 2.4, 2.25, 2.6, 4.21),  # dLGN10302015
                ('dLGN', 'fabee06', 2.5, 2.5, 2.7, 4.21),  # dLGN12032015
                ('dLGN', 'fabee02', 2.3, 2.4, 2.7, 4.21),  # dLGNDeeper
                ('dLGN', 'fabee03', 2.3, 2.3, 2.6, 4.21),  # dLGNmod
                ('dLGN', 'fabee04', 2.3, 2.4, 2.6, 4.21),  # dLGNMoreVentralLateral
                ('_Test', 'lambda', 4.21, 0, 0, 4.21),  # dLGNMoreVentralLateral
                ('_Test', 'bregma', 0, 0, 0, 4.21),  # dLGNMoreVentralLateral
                ]


@schema
class GuidanceMethod(dj.Lookup):
    definition = """
    # guidance method for injections

    guidance                    : char(20)
    ---
    """

    @property
    def contents(self):
        yield from zip(['2P','stereotactic','intrinsic','other'])

@schema
class VirusInjection(dj.Manual):
    definition = """
    # Virus Injection

    -> mice.Mice
    -> virus.Virus
    -> Site
    ---
    -> GuidanceMethod
    volume=null                   : double      # injection volume in nl
    speed=null                    : double      # injection speed [nl/min]
    toi=CURRENT_TIMESTAMP         : timestamp   # time of injection
    """

@schema
class InjectionLocation(dj.Manual):
    definition = """
    # Adjusted stereotactic coordinates for injection

    ->VirusInjection
    ->AtlasStereotacticTargets
    ---
    lambda_bregma                 : double    # distance between lambda and bregma in mm as measured
    caudal                        : double    # coordinate caudal from bregma in mm
    lateral                       : double    # lateral coordinate in mm
    ventral                       : double    # coordinate ventral from cortical surface in mm
    adjustment                    : double    # adjustement factor to convert atlas coordinates to this injection
    """
