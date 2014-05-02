#! /usr/bin/env python
'''
This file is part of ConfigShell.
Copyright (c) 2011-2014 by Datera, Inc

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations
under the License.
'''

import re
from distutils.core import setup
import configshell

PKG = configshell
VERSION = str(PKG.__version__)
(AUTHOR, EMAIL) = re.match('^(.*?)\s*<(.*)>$', PKG.__author__).groups()
URL = PKG.__url__
LICENSE = PKG.__license__
SCRIPTS = []
DESCRIPTION = PKG.__description__

setup(name=PKG.__name__,
      description=DESCRIPTION,
      version=VERSION,
      author=AUTHOR,
      author_email=EMAIL,
      license=LICENSE,
      url=URL,
      scripts=SCRIPTS,
      packages=[PKG.__name__],
      package_data = {'':[]})
