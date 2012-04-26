#
# SISPA-install-fabfile.py
#

import os.path, re
from fabric.api import cd, env, hide, local, run, settings, sudo, task
from fabric.network import disconnect_all

@task
def install():
    try:
        _print_env_variables()
        _initialize_dirs()
    finally:
        disconnect_all()

def _print_env_variables():
    print("user: %(user)s" % env)
    print("host: %(host)s" % env)
    print("PROJECT ROOT: %(PROJECT_ROOT)s" % env)
    print("SCRATCH ROOT: %(SCRATCH_ROOT)s" % env)
    print("TOOLS ROOT: %(TOOLS_ROOT)s" % env)

def _initialize_dirs():
    sudo("mkdir -p %(PROJECT_ROOT)s" % env)
    sudo("mkdir -p %(SCRATCH_ROOT)s" % env)
    sudo("mkdir -p %(TOOLS_ROOT)s" % env)
