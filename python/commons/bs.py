import datajoint as dj

schema = dj.schema('dimitri_brain_state', locals())

schema.spawn_missing_classes()