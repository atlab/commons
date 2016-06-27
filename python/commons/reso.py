import datajoint as dj

schema = dj.schema('common_resonant', locals())
schema.spawn_missing_classes()