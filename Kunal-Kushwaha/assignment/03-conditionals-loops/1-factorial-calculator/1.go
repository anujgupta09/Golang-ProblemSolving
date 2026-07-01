// 1. Factorial Program In Java
package main

import "fmt"

func main() {
	var n float64
	var factorial float64 = 1
	fmt.Scan(&n)
	var i float64
	for i = 1; i <= n; i++ {
		factorial *= i
	}
	fmt.Println("Factorial of ", n, " is ", factorial)
}
