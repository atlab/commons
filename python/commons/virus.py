import datajoint as dj

schema = dj.schema('common_virus', locals())


@schema
class Gene(dj.Manual):
    definition = """
    # lookup table of virus genes

    gene_id                     : char(12)      # identifier of the gne
    ---
    function                    : varchar(1024) # anticipated function of that gene
    dna_source                  : varchar(255)  # source of the DNA
    risk="no known risk"        : varchar(512) # risk for humans
    """


@schema
class Type(dj.Lookup):
    definition = """
    # table of virus types

    virus_type      : char(12)      # unique identifier for the virus type
    ---

    """

    contents = [(t,) for t in ['AAV', 'Rabies', 'Lenti']]


@schema
class Source(dj.Lookup):
    definition = """
    # table of vendors and sources of viruses

    source_id        : tinyint      # index of the source
    ---
    source_name      : varchar(50)  # real name of the source
    """

    @property
    def contents(self):
        yield from enumerate(['Penn', 'UNC', 'Homegrown', 'MIT'])


@schema
class Promoter(dj.Lookup):
    definition = """
    # table of viral promoters

    promoter        : char(12)   # promotor
    ---
    """

    contents = [(p,) for p in ['CamKIIa', 'hSyn', 'EF1a', 'CAG', 'CMV']]


@schema
class ViralPromoter(dj.Manual):
    definition = """
    # membership table with viral promoters

    -> Virus
    ---
    -> Promoter
    """


@schema
class Opsin(dj.Lookup):
    definition = """
    # lookup table of virus opsins

    opsin_id     : char(12)  # identifier of the opsin
    ---

    """

    contents = [(o,) for o in ['ChR2(H134R)', 'ChR2(E123T/T159C)', 'ArchT1.0']]


@schema
class ViralOpsin(dj.Manual):
    definition = """
    # membership table with viral opsins

    -> Virus
    -> Opsin
    ---
    """


@schema
class Conditional(dj.Manual):
    definition = """
    # system for conditional expression

    -> Virus
    ---
    condition     : enum('floxed','flipped','tet-on','tet-off')
    """


@schema
class Serotype(dj.Lookup):
    definition = """
    # virus serotypes

    serotype            : char(12)    # serotype of the virus
    ---
    """

    contents = [(s,) for s in ['AAV2/1', 'AAV2', 'AAV2/5', 'AAV2/8']]


@schema
class ViralSerotype(dj.Manual):
    definition = """
    # membership table for viral serotypes

    -> Virus
    ---
    -> Serotype
    """


@schema
class Virus(dj.Manual):
    definition = """
    # table of viruses
    virus_id                    : int  # unique id for each produced or purchased virus
    ---
    -> Gene
    -> Type
    -> Source
    virus_lot=NULL              : varchar(64)               # virus lot
    virus_titer=NULL            : float                     # virus titer
    virus_notes=""              : varchar(4095)             # free-text notes
    virus_ts=CURRENT_TIMESTAMP  : timestamp                 # automatic
    """


@schema
class ViralPlasmid(dj.Manual):
    definition = """
    # table of viral plasmids

    -> Gene
    viral_vector    : char(20)      # name of the eukaryotic vector
    ---
    point_of_use    : varchar(255)  # species of cells
    """


@schema
class ProcaryoticPlasmid(dj.Manual):
    definition = """
    # table of bacterial plasmids

    -> Gene
    procaryotic_vector    : char(20)      # name of the eukaryotic vector
    ---
    point_of_use          : varchar(255)  # species of cells
    """
