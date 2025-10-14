use std::io;

fn greet() -> String {
    format!("Hello, World!")
}

fn main() {
    let message = greet();
    println!("{}", message);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_greet() {
        assert_eq!(greet(), "Hello, World!");
    }
}
