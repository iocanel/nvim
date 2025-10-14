package com.iocanel;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

public class GreetingServiceTest {

  @Test
  public void testGreet() {
    GreetingService greetingService = new GreetingService();
    String result = greetingService.greet();
    assertEquals("Hello, World!", result);
  }
}

