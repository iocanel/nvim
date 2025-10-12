use std::io;

fn greet(name: &str) -> String {
    format!("Hello, {}!", name)
}

fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn main() {
    println!("Welcome to Rust Hello World!");
    
    let message = greet("World");
    println!("{}", message);
    
    println!("Enter your name:");
    let mut input = String::new();
    io::stdin().read_line(&mut input).expect("Failed to read line");
    let name = input.trim();
    
    let personal_greeting = greet(name);
    println!("{}", personal_greeting);
    
    let result = add(5, 3);
    println!("5 + 3 = {}", result);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        assert_eq!(greet("Alice"), "Hello, Alice!");
        assert_eq!(greet("Bob"), "Hello, Bob!");
    }

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
        assert_eq!(add(-1, 1), 0);
        assert_eq!(add(0, 0), 0);
    }

    #[test]
    fn test_add_large_numbers() {
        assert_eq!(add(1000, 2000), 3000);
    }
}