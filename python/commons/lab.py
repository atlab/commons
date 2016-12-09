import sys
import os
import numpy as np

import datajoint as dj

schema = dj.schema('common_lab', locals())

@schema
class Paths(dj.Lookup):
    definition = ...

    def get_local_path(self, path, local_os=None):

        # determine local os
        if local_os is None:
            local_os = sys.platform
            local_os = local_os[:(min(3, len(local_os)))]
        if local_os.lower() == 'glo':
            local = 0
            home = '~'

        elif local_os.lower() == 'lin':
            local = 1
            home = os.environ['HOME']

        elif local_os.lower() == 'win':
            local = 2
            home = os.environ['HOME']

        elif local_os.lower() == 'dar':
            local = 3
            home = '~'

        else:
            raise NameError('unknown OS')

        path = path.replace(os.path.sep, '/')
        path = path.replace('~', home)

        mapping = np.asarray(self.fetch['global', 'linux', 'windows', 'mac'])
        size = mapping.shape
        for i in range(size[1]):
            for j in range(size[0]):
                n = len(mapping[j, i])
                if j != local and path[:n] == mapping[j, i][:n]:
                    path = os.path.join(mapping[local, i], path[n+1:])
                    break

        if os.path.sep == '\\' and local_os.lower() != 'glo':
            path = path.replacec('/', '\\')

        else:
            path = path.replace('\\', '/')

        return path



