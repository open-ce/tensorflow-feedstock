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

# TEST TensorFlow API r1
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import tensorflow.compat.v1 as tf
from tensorflow.python.platform import googletest

class MinimalTFInstallationTest(googletest.TestCase):

  def setUp(self):
    super(MinimalTFInstallationTest, self).setUp()
    tf.disable_v2_behavior()
    self.sess = tf.Session()

  def test_hello_world(self):
    input_string = 'Hello, TensorFlow!'
    hello = tf.constant(input_string)
    output_string = self.sess.run(hello).decode()
    self.assertEqual(input_string, output_string)

  def test_addition(self):
    a = tf.constant(10)
    b = tf.constant(32)
    expected_result = 42
    actual_result = self.sess.run(a + b)
    self.assertEqual(expected_result, actual_result)

if __name__ == "__main__":
  googletest.main()
