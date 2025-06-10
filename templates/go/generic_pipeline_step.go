func step[T any, U any](in <-chan T, function func(T) U) <-chan U {
	out := make(chan U)
	go func() {
		defer close(out)
		for item := range in {
			out <- function(item)
		}
	}()
	return out
}
