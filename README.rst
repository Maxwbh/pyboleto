========
pyboleto
========

.. image:: https://secure.travis-ci.org/eduardocereto/pyboleto.png?branch=master
   :target: http://travis-ci.org/#!/eduardocereto/pyboleto

.. _pyboleto-synopsis:

pyboleto provides a python class to generate "boletos de cobranca" as these
are the Brazilian equivalent for invoices.

It's easy to implement classes for new banks.

This class is still in development and currently has no documented API.

.. contents::
    :local:

.. _pyboleto-implemented-bank:

Implemented Banks
=================

You can help writing code for more banks or printing and testing current
implementations.

For now here's where we are.

 +----------------------+----------------+-----------------+------------+
 | **Bank**             | **Carteira /** | **Implemented** | **Tested** |
 |                      | **Convenio**   |                 |            |
 +======================+================+=================+============+
 | **Banco do Brasil**  | 18             | Yes             | Yes        |
 +----------------------+----------------+-----------------+------------+
 | **Banrisul**         | -              | Yes             | Yes        |
 +----------------------+----------------+-----------------+------------+
 | **Bradesco**         | 06, 03         | Yes             | Yes        |
 +----------------------+----------------+-----------------+------------+
 | **Caixa Economica**  | SR             | Yes             | No         |
 +----------------------+----------------+-----------------+------------+
 | **HSBC**             | CNR, CSB       | Yes             | No         |
 +----------------------+----------------+-----------------+------------+
 | **Itau**             | 175, 174, 178, | Yes             | No         |
 |                      | 104, 109, 157  |                 |            |
 +----------------------+----------------+-----------------+------------+
 | **Real**             | 57             | Yes             | No         |
 +----------------------+----------------+-----------------+------------+
 | **Santander**        | 102, 101, 201  | Yes             | No         |
 +----------------------+----------------+-----------------+------------+
 | **BRB**              | -              | Yes             | Yes        |
 +----------------------+----------------+-----------------+------------+

.. _pyboleto-docs:

Documentation
=============

http://packages.python.org/pyboleto/

The best way to learn how to create Boletos using pyboleto is to look at the
examples at `pyboleto_sample.py`_


.. _pyboleto_sample.py: https://github.com/eduardocereto/pyboleto/blob/master/bin/pyboleto_sample.py

.. _pyboleto-installation:

Installation
============

You can install pyboleto either via the Python Package Index (PyPI)
or from source.

To install using pip::

    $ pip install pyboleto


.. _pyboleto-installing-from-source:

Installing from source
----------------------

Download the latest version of pyboleto from
http://pypi.python.org/pypi/pyboleto/

You can install it by doing the following::

    $ tar xvfz pyboleto-0.2.11.tar.gz
    $ cd pyboleto-0.2.11
    $ pip install .

Or for development mode (editable install)::

    $ pip install -e .

.. _pyboleto-installing-from-git:

Using the development version
-----------------------------

You can clone the repository and install in development mode::

    $ git clone https://github.com/eduardocereto/pyboleto.git
    $ cd pyboleto
    $ pip install -e .

Building distributions
----------------------

To build source and wheel distributions using the modern Python build tools::

    $ pip install build
    $ python -m build

This will create distribution files in the ``dist/`` directory.

.. _pyboleto-unittests:

Executing unittests
===================

To run the test suite, install the package with test dependencies and run pytest::

    $ pip install -e .[test]
    $ pytest

You may also need `pdftohtml`_ for some PDF-related tests::

    $ sudo apt-get install poppler-utils  # On Debian/Ubuntu
    $ brew install poppler                # On macOS

.. _pdftohtml: http://poppler.freedesktop.org/

.. _pyboleto-license:

License
=======

This software is licensed under the `New BSD License`. See the ``LICENSE``
file in the top distribution directory for the full license text.

.. vim:tw=0:sw=4:et
