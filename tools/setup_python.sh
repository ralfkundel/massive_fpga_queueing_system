#!/bin/bash

sudo apt -y install python3-pip virtualenv

PYTHON_VIRTUALENV="python_virtualenv"

create_env () {
    # create virtual environment and activate
    python3_dir=$(which python3)
    virtualenv -p $python3_dir $PYTHON_VIRTUALENV
    source $PYTHON_VIRTUALENV/bin/activate
}

create_env;
python3 -m pip install kamene
deactivate;
