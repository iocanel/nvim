#!/usr/bin/env python3
"""Tests for the helloworld module."""

import unittest
from unittest.mock import patch
import sys
import os

# Add the parent directory to the path so we can import helloworld
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from helloworld import Calculator, greet, get_environment_info


class TestCalculator(unittest.TestCase):
    """Test cases for the Calculator class."""

    def setUp(self):
        """Set up test fixtures before each test method."""
        self.calc = Calculator("Test Calculator")

    def test_calculator_initialization(self):
        """Test calculator initialization."""
        self.assertEqual(self.calc.name, "Test Calculator")
        self.assertEqual(len(self.calc.history), 0)

    def test_add_method(self):
        """Test the add method."""
        result = self.calc.add(5, 3)
        self.assertEqual(result, 8)
        self.assertEqual(len(self.calc.history), 1)
        self.assertIn("5 + 3 = 8", self.calc.history[0])

    def test_multiply_method(self):
        """Test the multiply method."""
        result = self.calc.multiply(4, 6)
        self.assertEqual(result, 24)
        self.assertEqual(len(self.calc.history), 1)
        self.assertIn("4 * 6 = 24", self.calc.history[0])

    def test_power_method(self):
        """Test the power method."""
        result = self.calc.power(2, 3)
        self.assertEqual(result, 8)
        self.assertEqual(len(self.calc.history), 1)
        self.assertIn("2 ^ 3 = 8", self.calc.history[0])

    def test_history_functionality(self):
        """Test history tracking and clearing."""
        self.calc.add(1, 2)
        self.calc.multiply(3, 4)
        
        history = self.calc.get_history()
        self.assertEqual(len(history), 2)
        
        self.calc.clear_history()
        self.assertEqual(len(self.calc.history), 0)

    def test_floating_point_operations(self):
        """Test operations with floating point numbers."""
        result = self.calc.add(1.5, 2.3)
        self.assertAlmostEqual(result, 3.8, places=1)


class TestGreetFunction(unittest.TestCase):
    """Test cases for the greet function."""

    def test_greet_with_name(self):
        """Test greeting with a name."""
        result = greet("Alice")
        self.assertEqual(result, "Hello, Alice!")

    def test_greet_without_name(self):
        """Test greeting without a name."""
        result = greet()
        self.assertEqual(result, "Hello, World!")

    def test_greet_with_none(self):
        """Test greeting with None as name."""
        result = greet(None)
        self.assertEqual(result, "Hello, World!")


class TestEnvironmentInfo(unittest.TestCase):
    """Test cases for environment info function."""

    def test_get_environment_info_keys(self):
        """Test that environment info returns expected keys."""
        info = get_environment_info()
        expected_keys = {
            "python_version",
            "current_directory", 
            "home_directory",
            "platform"
        }
        self.assertEqual(set(info.keys()), expected_keys)

    def test_get_environment_info_types(self):
        """Test that environment info returns correct types."""
        info = get_environment_info()
        self.assertIsInstance(info["python_version"], str)
        self.assertIsInstance(info["current_directory"], str)
        self.assertIsInstance(info["home_directory"], str)
        self.assertIsInstance(info["platform"], str)

    @patch('os.getcwd')
    def test_current_directory_mock(self, mock_getcwd):
        """Test current directory with mocking."""
        mock_getcwd.return_value = "/test/directory"
        info = get_environment_info()
        self.assertEqual(info["current_directory"], "/test/directory")


class TestIntegration(unittest.TestCase):
    """Integration tests combining multiple components."""

    def test_calculator_with_multiple_operations(self):
        """Test calculator with multiple operations."""
        calc = Calculator("Integration Test")
        
        # Perform multiple operations
        calc.add(10, 20)
        calc.multiply(5, 6)
        calc.power(3, 2)
        
        history = calc.get_history()
        self.assertEqual(len(history), 3)
        
        # Check that all operations are recorded
        self.assertTrue(any("10 + 20" in entry for entry in history))
        self.assertTrue(any("5 * 6" in entry for entry in history))
        self.assertTrue(any("3 ^ 2" in entry for entry in history))


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)