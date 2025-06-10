  defer func() {
    if r := recover(); r != nil {
      fmt.Println("Recovered from panic:", r)
      fmt.Println("Stack trace:")
      debug.PrintStack()
    }
  }()
