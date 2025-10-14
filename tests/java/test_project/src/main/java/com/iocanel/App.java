package com.iocanel;

/**
 * Hello world!
 *
 */
public class App {
  public static void main(String[] args) {
    GreetingService greetingService = new GreetingService();
    System.out.println(greetingService.greet());
  }
}
