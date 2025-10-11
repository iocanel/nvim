#!/usr/bin/env python3
"""Simple Python module for testing LSP functionality."""

import math
import os
from typing import List, Optional


class Calculator:
    """A simple calculator class for testing."""

    def __init__(self, name: str = "Calculator"):
        self.name = name
        self.history: List[str] = []

    def add(self, a: float, b: float) -> float:
        """Add two numbers."""
        result = a + b
        self.history.append(f"{a} + {b} = {result}")
        return result

    def multiply(self, a: float, b: float) -> float:
        """Multiply two numbers."""
        result = a * b
        self.history.append(f"{a} * {b} = {result}")
        return result

    def power(self, base: float, exponent: float) -> float:
        """Calculate base raised to the power of exponent."""
        result = math.pow(base, exponent)
        self.history.append(f"{base} ^ {exponent} = {result}")
        return result

    def get_history(self) -> List[str]:
        """Get calculation history."""
        return self.history.copy()

    def clear_history(self) -> None:
        """Clear calculation history."""
        self.history.clear()


def greet(name: Optional[str] = None) -> str:
    """Greet someone with an optional name."""
    if name:
        return f"Hello, {name}!"
    return "Hello, World!"


def get_environment_info() -> dict:
    """Get some environment information."""
    return {
        "python_version": os.sys.version,
        "current_directory": os.getcwd(),
        "home_directory": os.path.expanduser("~"),
        "platform": os.name,
    }


def main():
    """Main function to demonstrate the calculator."""
    print(greet("Python Developer"))
    
    calc = Calculator("Test Calculator")
    
    # Some calculations
    result1 = calc.add(10, 5)
    result2 = calc.multiply(3, 4)
    result3 = calc.power(2, 8)
    
    print(f"Addition result: {result1}")
    print(f"Multiplication result: {result2}")
    print(f"Power result: {result3}")
    
    print("\nCalculation History:")
    for entry in calc.get_history():
        print(f"  {entry}")
    
    print("\nEnvironment Info:")
    env_info = get_environment_info()
    for key, value in env_info.items():
        print(f"  {key}: {value}")


if __name__ == "__main__":
    main()