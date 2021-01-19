#!/usr/bin/env python
# *****************************************************************
# (C) Copyright IBM Corp. 2016, 2019. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
