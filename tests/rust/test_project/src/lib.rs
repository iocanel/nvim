pub fn calculate(a: i32, b: i32) -> i32 {
    a * b + 10
}

pub fn is_even(n: i32) -> bool {
    n % 2 == 0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate() {
        assert_eq!(calculate(2, 3), 16); // 2 * 3 + 10 = 16
        assert_eq!(calculate(0, 5), 10); // 0 * 5 + 10 = 10
    }

    #[test]
    fn test_is_even() {
        assert!(is_even(2));
        assert!(is_even(0));
        assert!(!is_even(1));
        assert!(!is_even(3));
    }
}