#!/usr/bin/env python
# *****************************************************************
#
# Licensed Materials - Property of IBM
#
# (C) Copyright IBM Corp. 2016, 2019. All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# *****************************************************************

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import tensorflow as tf
from tensorflow.python.platform import googletest

class MinimalTFInstallationTest(googletest.TestCase):

  def setUp(self):
    super(MinimalTFInstallationTest, self).setUp()

  def test_hello_world(self):
    input_string = 'Hello, TensorFlow!'
    hello = tf.constant(input_string)
    output_string = hello.numpy().decode()
    self.assertEqual(input_string, output_string)

  def test_addition(self):
    actual_result = tf.add(10, 32).numpy()
    expected_result = 42
    self.assertEqual(expected_result, actual_result)

if __name__ == "__main__":
  googletest.main()
