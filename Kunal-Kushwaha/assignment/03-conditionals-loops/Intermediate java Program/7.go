// 7. Power In Java
package main

import "fmt"

func main() {
	var num, pow, result int
	fmt.Scan(&num, &pow)
	result = num
	for i := 2; i <= pow; i++ {
		result *= result
		fmt.Println("i : ", i, "result : ", result)
	}
	fmt.Println(result)
}
