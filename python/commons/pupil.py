import datajoint as dj

schema = dj.schema('dimitri_pupil', locals())


schema.spawn_missing_classes()