import datajoint as dj

schema = dj.schema('common_optical', locals())

schema.spawn_missing_classes()