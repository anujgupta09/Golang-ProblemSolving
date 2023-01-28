// 3. Calculate Average Of N Numbers
package main

import "fmt"

func main() {
	var n float32
	var sum float32 = 0
	var totalNumber = 0
	for {
		fmt.Print("Enter the number : ")
		fmt.Scan(&n)
		if n == 0 {
			break
		}
		totalNumber += 1
		sum += n
	}
	fmt.Println("Average :", sum/float32(totalNumber))
}
