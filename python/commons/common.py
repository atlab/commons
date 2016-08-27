import datajoint as dj

schema = dj.schema('common', locals())


schema.spawn_missing_classes()