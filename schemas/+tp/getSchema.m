function obj = getSchema
persistent schemaObject

if isempty(schemaObject)
    common.getSchema;
    psy.getSchema;
    schemaObject = dj.Schema(dj.conn, 'tp', 'common_two_photon');
end

obj = schemaObject;
end