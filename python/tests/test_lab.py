from nose.tools import assert_raises, assert_equal, \
    assert_false, assert_true, assert_list_equal, \
    assert_tuple_equal, assert_dict_equal, raises

import os
import random
from commons import lab
from pipeline import experiment


def test_paths():
    rel = experiment.Session() * experiment.Scan.EyeVideo() * experiment.Scan.BehaviorFile().proj(
            hdf_file='filename')

    path_info = random.choice(rel.fetch.as_dict())

    tmp = path_info['hdf_file'].split('.')
    if '%d' in tmp[0]:
        # new version
        path_info['hdf_file'] = tmp[0][:-2] + '0.' + tmp[-1]
    else:
        path_info['hdf_file'] = tmp[0][:-1] + '0.' + tmp[-1]

    hdf_path = lab.Paths().get_local_path('{behavior_path}/{hdf_file}'.format(**path_info))
    avi_path = lab.Paths().get_local_path('{behavior_path}/{filename}'.format(**path_info))

    assert_true(os.path.isfile(avi_path) and os.path.isfile(hdf_path))

