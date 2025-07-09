import { createInterface } from "readline"

function prompt(message: string): Promise<string> {
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout
  })

  return new Promise(resolve => {
    rl.question(message, (answer) => {
      rl.close()
      resolve(answer)
    })
  })
}
