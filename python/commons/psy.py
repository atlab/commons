import datajoint as dj

schema = dj.schema('common_psy', locals())

schema.spawn_missing_classes()