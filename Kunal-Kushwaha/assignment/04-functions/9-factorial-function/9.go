/*
9. [Write a program to print the factorial of a number by defining a method named 'Factorial'.](https://www.javatpoint.com/factorial-program-in-java)
Factorial of any number n is represented by n! and is equal to 1 * 2 * 3 * .... * (n-1) *n. E.g.- <br/>
<pre>
4! = 1 * 2 * 3 * 4 = 24
3! = 3 * 2 * 1 = 6
2! = 2 * 1 = 2
Also,
1! = 1
0! = 1
</pre>

*/

package main

import "fmt"

func main() {
	var num float64
	fmt.Scan(&num)
	result := factorial(num)
	fmt.Println(result)
}
func factorial(num float64) float64 {
	var result float64 = 1
	var i float64
	for i = 1; i <= num; i++ {
		result *= i
	}
	return result
}
