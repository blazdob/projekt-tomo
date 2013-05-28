import os.path
import tempfile

from fabric.api import *
from fabric.contrib.console import confirm

env.hosts = ['matija@tyrion.fmf.uni-lj.si']

FIXTURES = [
    # 'auth.User',
    'tomo.Course',
    'tomo.ProblemSet',
    # 'tomo.Language',
    'tomo.Problem',
    'tomo.Part',
    # 'tomo.Submission',
    # 'tomo.Attempt',
]

env.srv_directory = '/srv/'
env.project_repository = 'git@git.fmf.uni-lj.si:matijapretnar/projekt-tomo.git'
env.tomo_repository = 'git@github.com:matijapretnar/tomo.git'

@task
def setup():
    with cd(env.srv_directory):
        sudo('git clone {project_repository} {project_name}'.format(**env))
    with cd(env.home):
        sudo('virtualenv --no-site-packages virtualenv')
        with prefix('source virtualenv/bin/activate'):
            sudo('pip install -r requirements/{project_name}.txt'.format(**env))
        sudo('git clone {tomo_repository}'.format(**env))
    update()

@task
def production():
    set_project('tomo-production')

@task
def std():
    set_project('std-production')

@task
def lock():
    with cd(env.home):
        sudo('touch project/lock')
    restart()

@task
def unlock():
    with cd(env.home):
        sudo('rm project/lock')
    restart()

@task
def update():
    lock()
    with cd('tomo'):
        git('pull')
    manage('collectstatic --noinput')
    manage('syncdb')
    manage('migrate')
    unlock()

@task
def get_dump():
    for fixture in FIXTURES:
        with hide('stdout'):
            json = manage('dumpdata --indent=2 {0}'.format(fixture))
        with open('fixtures/{0}.json'.format(fixture), 'w') as f:
            f.write(json)

@task
def edit_settings():
    edit(os.path.join(env.home, 'project/settings.py'), use_sudo=True)

@task
def edit_apache():
    edit('/etc/apache2/sites-available/tomo.fmf.uni-lj.si', use_sudo=True)

@task
def restart_apache():
    sudo('apache2ctl graceful')

@task
def reset_tomodev():
    if confirm('Are you sure you want to reset the staging database?',
               default=False):
        postgres("dropdb tomodev")
        postgres("createdb -T tomo tomodev")

@task
def reset_local():
    local('touch tomo.db')
    local('rm tomo.db')
    local('./manage.py syncdb --noinput')
    local('./manage.py migrate')
    local('./manage.py loaddata fixtures/*.json')

# Auxiliary commands

def set_project(project_name):
    env.project_name = project_name
    env.home = os.path.join(env.srv_directory, project_name)

def git(command, subdir=""):
    with cd(env.home):
        with cd(subdir):
            return sudo('git {0}'.format(command))

def manage(command):
    with cd(env.home):
        with prefix('source virtualenv/bin/activate'):
            return sudo('./manage.py {0}'.format(command))

def postgres(command):
    sudo('su -c "{0}" postgres'.format(command))

def restart():
    with cd(env.home):
        sudo('touch project/wsgi.py')

def edit(remote_file, use_sudo=False):
    _, temporary_filename = tempfile.mkstemp(suffix=os.path.splitext(remote_file)[1])
    print temporary_filename
    get(remote_file, temporary_filename)
    local('$EDITOR {0}'.format(temporary_filename))
    put(temporary_filename, remote_file, use_sudo=use_sudo)
    local('rm {0}'.format(temporary_filename))

set_project('tomodev')