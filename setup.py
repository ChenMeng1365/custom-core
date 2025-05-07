#coding:utf-8
from setuptools import setup, find_packages

setup(
    name="custom-core",
    version="1.0.3",

    install_requires=[
        # 'IPy'
    ],
    py_modules=['pycc'],

    author='Matthrewchains',
    author_email='matthrewchains@gmail.com',
    description='custom-core ver. python',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/ChenMeng1365/custom-core',

    packages=find_packages(),
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)
