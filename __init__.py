####################################################################################
# HOW TO USE                                                                       #
####################################################################################
# 
# 1. get tools:
# pip install setuptools twine
# 
# 2. build and upload:(to testpypi)
# python setup.py sdist bdist_wheel
# twine check dist/*
# twine upload --repository testpypi dist/*
#
# 3. install:
# pip install --index-url https://test.pypi.org/simple/ custom-core
#
# 4. import:
# python >>>> 
# from pycc import *
#