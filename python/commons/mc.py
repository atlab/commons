import datajoint as dj

schema = dj.schema('common_microcolumns', locals())

schema.spawn_missing_classes()