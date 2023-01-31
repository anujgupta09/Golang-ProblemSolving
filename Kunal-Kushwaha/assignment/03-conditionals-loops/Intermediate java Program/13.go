// 13. Sum Of N Numbers

package main

import "fmt"

func main() {
	var n, sum int
	sum = 0
	count := 0
	for {
		count++
		fmt.Println(count)
		fmt.Print("Enter num : ")
		fmt.Scan(&n)
		if n == 0 {
			break
		}
		sum += n
	}
	fmt.Println(sum)
}
