function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    reso.getSchema;
    schemaObject = dj.Schema(dj.conn, 'bs', 'dimitri_brain_state');
end
obj = schemaObject;
end