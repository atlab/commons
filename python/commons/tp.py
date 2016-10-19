import datajoint as dj

schema = dj.schema('common_two_photon', locals())


schema.spawn_missing_classes()