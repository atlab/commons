import datajoint as dj

schema = dj.schema('common_mice', locals())

schema.spawn_missing_classes()