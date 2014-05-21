function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    reso.getSchema;
    psy.getSchema;
    patch.getSchema;
    schemaObject = dj.Schema(dj.conn, 'pupil', 'dimitri_pupil');
end
obj = schemaObject;
end