#!/usr/bin/env bash
# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: 2020-09-02 19:56:58
# @DESCRIPTION:

# Number of input parameters


git pull

source venv/bin/activate
pip install -r requirements.txt

cd gsca/gsca-angular/
npm install

npm run build:prod