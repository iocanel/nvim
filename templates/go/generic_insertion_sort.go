func insert[T cmp.Ordered](array []T, value T) []T {
  if len(array) == 0 {
    return []T{value}
  }

  index := 0
  for index < len(array) && array[index] < value {
    index++
  }

	// Allocate one extra space for the result
	array = append(array, value) // append dummy to grow slice

	// Shift elements right
	copy(array[index+1:], array[index:])

  // Insert the value at the correct position
	array[index] = value
  
  return array
}
