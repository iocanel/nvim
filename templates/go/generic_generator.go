func generator[T any](items ...T) <-chan T {
	out := make(chan T)
	go func() {
		defer close(out)
		for _, item := range items {
			out <- item
		}
	}()
	return out
}
