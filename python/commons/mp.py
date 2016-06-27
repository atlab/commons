import datajoint as dj

schema = dj.schema('common_multipatch', locals())

schema.spawn_missing_classes()